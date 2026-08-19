<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The workflow uses `actions/checkout@v6` (a mutable tag, not a full 40-character commit SHA) in every job. If the tag is moved or the repository is compromised, arbitrary code could be injected into the runner. All five occurrences of `actions/checkout@v6` must be pinned to a full SHA digest.

Locations:

- `.github/workflows/test.yml:21`
- `.github/workflows/test.yml:38`
- `.github/workflows/test.yml:51`
- `.github/workflows/test.yml:67`
- `.github/workflows/test.yml:83`

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (sourced from `inputs.package_path` and `inputs.build_parameters`) are expanded unquoted inside shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` and `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can achieve command injection. These variables must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:63`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `$(eval echo ${COVERAGE_OBJECTS})` expands `${COVERAGE_OBJECTS}` unquoted inside an `eval` context. `COVERAGE_OBJECTS` is set from `covobjs`, which is constructed from `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (user-controlled inputs). This allows an attacker to inject arbitrary shell commands through a crafted `package_path` or `build_parameters` input. The offending line is: `$(eval echo ${COVERAGE_OBJECTS})`.

Locations:

- `action.yml:100`

### github-env-injection (severity: high)

In the `determine-package-info` step, `covobjs` and `covpath` are derived from `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (which come from `inputs.package_path` and `inputs.build_parameters`) and are written to `$GITHUB_ENV` without sanitization: `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"`. A newline character embedded in an input value can inject arbitrary environment variables into subsequent steps. The required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`) is missing before each write.

Locations:

- `action.yml:80`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are written to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without sanitization. A newline in any of these input values can inject arbitrary key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting outputs of subsequent steps. The required `tr -d '\n\r'` sanitization is missing before the write.

Locations:

- `action.yml:113`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all 5 findings across 2 files:

1. unpinned-uses (.github/workflows/test.yml): Pinned all 6 occurrences of `actions/checkout@v6` to full SHA `d23441a48e516b6c34aea4fa41551a30e30af803 # v6`.

2. script-injection (action.yml line 63): PACKAGE_PATH is now used with `${PACKAGE_PATH:+"${PACKAGE_PATH}"}` (safe optional single-value form). BUILD_PARAMETERS is a list of flags, so it's tokenized via xargs into a bash array `build_params` and expanded as `"${build_params[@]}"`.

3. script-injection (action.yml line 100): Replaced `$(eval echo ${COVERAGE_OBJECTS})` with a safe array approach. Coverage objects are built into a `cov_args` array (using `--object path` pairs without single-quoted paths), serialized to COVERAGE_OBJECTS, then re-tokenized via xargs in the next step and expanded as `"${cov_args[@]}"`.

4. github-env-injection (action.yml line 80): covobjs and covpath are sanitized with `tr -d '\n\r'` before writing to $GITHUB_ENV via printf.

5. github-env-injection (action.yml line 113): All 19 input-derived variables are sanitized with `tr -d '\n\r'` before writing to $GITHUB_OUTPUT via printf.

