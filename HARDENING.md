<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.7** was hardened automatically. 4 finding(s) were identified and resolved across 4 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — sourced from `inputs.package_path` and `inputs.build_parameters` — are expanded **unquoted** inside shell commands:
  `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`
  `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`
  `swift package ${PACKAGE_PATH} describe ...`
An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the intended argument context and execute arbitrary commands. Fix: double-quote every expansion, e.g. `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:62`
- `action.yml:70`
- `action.yml:71`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `${COVERAGE_OBJECTS}` is expanded **unquoted** inside a command substitution passed to `eval`:
  `$(eval echo ${COVERAGE_OBJECTS})`
`COVERAGE_OBJECTS` is an inherited env var (set in `$GITHUB_ENV` by the previous step) whose value is constructed from filesystem paths that can be influenced by `inputs.package_path` and `inputs.build_parameters`. The unquoted expansion inside `eval` allows shell metacharacters to be interpreted, enabling command injection.

Locations:

- `action.yml:120`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple `inputs.*` values are mapped to env vars (TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) and then written directly to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required newline-stripping sanitization (`printf '%s' "$VAR" | tr -d '\n\r'`). A caller-supplied value containing a newline character can inject additional key=value pairs into `GITHUB_OUTPUT`, potentially overwriting outputs consumed by downstream steps.

Locations:

- `action.yml:122`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: the `convert-coverage-report` step uses `eval` with command substitution (`$(...)`) to dynamically construct and execute a shell command:
  `$(eval echo ${COVERAGE_OBJECTS})`
This matches the `eval $()` pattern flagged by the `eval-dynamic` check. Combined with the unquoted `${COVERAGE_OBJECTS}` expansion, this allows dynamic code execution from a value that can be influenced by workflow inputs.

Locations:

- `action.yml:120`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all four findings in hardened/action/action.yml:

1. script-injection (determine-package-info step): PACKAGE_PATH is now conditionally expanded as ${PACKAGE_PATH:+"${PACKAGE_PATH}"} (drops out when empty, quoted when present). BUILD_PARAMETERS is tokenized into a bash array using xargs (quote-aware, handles multi-word flags like '-c release') and expanded as "${build_params[@]}".

2. script-injection + suspicious-run-content (convert-coverage-report step): Eliminated eval echo ${COVERAGE_OBJECTS} entirely. COVERAGE_OBJECTS is now stored as newline-separated plain paths via a heredoc (<<COVEOF) in $GITHUB_ENV. In the convert step, a while-read loop builds a cov_args array with --object= prefixes, expanded safely as "${cov_args[@]}".

3. github-env-injection (convert-coverage-report step): All 19 input-derived env vars written to $GITHUB_OUTPUT are now sanitized with printf '%s' "${VAR}" | tr -d '\n\r' before use in the printf command.

The Perl <> diamond operator was carefully preserved unchanged.

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection finding in the `determine-package-info` step of action.yml. The `covpath` variable (derived from caller-controlled `inputs.package_path`) was written to `$GITHUB_ENV` without sanitization. Fixed by adding `safe_covpath="$(printf '%s' "${covpath}" | tr -d '\n\r')"` before the echo, then using `safe_covpath` in the write. The `covobjs` variable is written using the heredoc form (`COVERAGE_OBJECTS<<COVEOF`...`COVEOF`), which is the correct multi-line value form — per the rules, this should NOT be sanitized as the heredoc delimiter already prevents injection and stripping newlines would corrupt the intentionally multi-line value.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection finding in action.yml at line 88. The COVERAGE_OBJECTS heredoc write to $GITHUB_ENV used a fixed delimiter 'COVEOF', which could be exploited by a crafted package name containing a line matching the delimiter, allowing early termination of the heredoc and injection of additional environment variables. The fix replaces the fixed delimiter with a randomly generated one: `cov_eof="COVEOF_$(openssl rand -hex 16)"`, making it cryptographically impossible for an attacker to predict or embed the delimiter in the covobjs value. The multi-line nature of covobjs (multiple file paths separated by newlines) means stripping newlines is not appropriate here; the random delimiter is the correct mitigation.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed lines 98-114 in action.yml: replaced backslash-escaped double quotes in format() strings (e.g., format(',\"root_dir\":\"{0}\"', ...)) with the correct upstream single-quoted format strings containing unescaped double quotes (e.g., format(',"root_dir":"{0}"', ...)). All 17 env vars in the convert-coverage-report step's env block were corrected: ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, and VERBOSE.

