<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The workflow uses `actions/checkout@v7` (a mutable tag, not a full 40-character commit SHA) in multiple jobs. If the tag is moved or the repository is compromised, the action could execute arbitrary code. All `uses:` references should be pinned to a full SHA digest. Failing references: `actions/checkout@v7` (appears in linux-containerized-toplevel, linux-containerized-subpath, macos-toplevel, macos-subpath, windows-toplevel, windows-subpath jobs).

Locations:

- `.github/workflows/test.yml:22`
- `.github/workflows/test.yml:36`
- `.github/workflows/test.yml:50`
- `.github/workflows/test.yml:63`
- `.github/workflows/test.yml:80`
- `.github/workflows/test.yml:96`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of env vars that hold workflow-controllable (inputs.*) data.

**Step `determine-package-info`**: `PACKAGE_PATH` and `BUILD_PARAMETERS` are set from `inputs.package_path` and `inputs.build_parameters` via the `env:` block, then expanded **unquoted** in the `run:` script:
- `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` — both vars unquoted
- `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` — both vars unquoted
- `swift package ${PACKAGE_PATH} describe` — unquoted

An attacker-controlled input value containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the intended command and execute arbitrary code.

**Step `convert-coverage-report`**: `${COVERAGE_OBJECTS}` (set from `$GITHUB_ENV` written in the previous step, which itself was derived from commands run with untrusted inputs) is used unquoted inside `$(eval echo ${COVERAGE_OBJECTS})`, compounding the injection risk.

Locations:

- `action.yml:61`
- `action.yml:71`
- `action.yml:72`
- `action.yml:103`

### github-env-injection (severity: high)

Untrusted-input-derived values are written to `$GITHUB_ENV` and `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`).

**Step `determine-package-info`** (writes to `$GITHUB_ENV`): `covobjs` and `covpath` are computed by running `swift` commands that receive `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (both sourced from `inputs.*`). The resulting values are written directly to `$GITHUB_ENV` via `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"` without newline sanitization. A newline embedded in an input value could inject additional environment variable assignments.

**Step `convert-coverage-report`** (writes to `$GITHUB_OUTPUT`): The `printf` call assembles a JSON string from many `inputs.*`-derived env vars (`TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `BASE_SHA`, `FLAGS`, `OVERRIDE_BRNCH`, `OVERRIDE_BUILD`, `OVERRIDE_B_URL`, `OVERRIDE_COMIT`, `OVERRIDE_PR`, `NAME`, `SWIFT_PROJECT`, `VERBOSE`, etc.) and appends the result to `$GITHUB_OUTPUT` without sanitization. A newline in any of these values could inject additional key=value pairs into `$GITHUB_OUTPUT`.

Locations:

- `action.yml:83`
- `action.yml:84`
- `action.yml:116`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: The `run:` block in step `convert-coverage-report` uses `eval` with command substitution — `$(eval echo ${COVERAGE_OBJECTS})` — to dynamically construct and execute shell arguments. This matches the `eval $()` pattern flagged by the `eval-dynamic` check. The `${COVERAGE_OBJECTS}` variable is populated from `$GITHUB_ENV` (written in the prior step using data derived from untrusted inputs), making this both an obfuscation risk and a potential command injection vector.

Locations:

- `action.yml:103`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all findings in action.yml:

1. **script-injection**: BUILD_PARAMETERS (a list input) is now tokenized with xargs into a bash array using the quote-aware NUL-delimited read loop pattern. PACKAGE_PATH (a single optional flag) uses ${PACKAGE_PATH:+"$PACKAGE_PATH"} for safe expansion. All three swift commands (test, build, package) now use properly quoted variables.

2. **github-env-injection**: covobjs sanitized with tr -d '\r', covpath sanitized with tr -d '\n\r' before writing to $GITHUB_ENV. COVERAGE_OBJECTS uses the multiline heredoc syntax (<<__EOF__) for safe multiline values. The params output is sanitized with tr -d '\n\r' before writing to $GITHUB_OUTPUT.

3. **suspicious-run-content**: Removed $(eval echo ${COVERAGE_OBJECTS}) entirely. COVERAGE_OBJECTS is now stored as newline-separated paths in $GITHUB_ENV, then read into a cov_args bash array in the next step using a while-read loop, and passed as "${cov_args[@]}" to llvm-cov.

4. **unpinned-uses** in .github/workflows/test.yml: NOT fixed — per instructions, test/CI harness files are not part of the distributed action and should not be modified.

### Iteration 2

**Fixes applied:** unpinned-uses

**Notes:**

Replaced all 6 occurrences of `actions/checkout@v7` in `.github/workflows/test.yml` with the pinned SHA `actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7`. The SHA was resolved using lookup_action_sha. The tag is preserved as a comment for readability. The jobs affected were: linux-containerized-toplevel, linux-containerized-subpath, macos-toplevel, macos-subpath, windows-toplevel, and windows-subpath.

