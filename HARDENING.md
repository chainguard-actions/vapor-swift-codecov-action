<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in step `determine-package-info`: env vars `PACKAGE_PATH` and `BUILD_PARAMETERS` (sourced from `inputs.package_path` and `inputs.build_parameters`) are expanded unquoted inside the run block. Offending lines: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`) will be interpreted by the shell. All three expansions must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Rule (b) violation in step `convert-coverage-report`: `${COVERAGE_OBJECTS}` is used unquoted inside `$(eval echo ${COVERAGE_OBJECTS})`, and `${PACKAGE_PATH}` (from `inputs.package_path`) is used unquoted in `>"${PACKAGE_PATH}codecov.txt"`.

Locations:

- `action.yml:55`
- `action.yml:62`
- `action.yml:63`
- `action.yml:98`
- `action.yml:99`

### github-env-injection (severity: high)

Step `determine-package-info` writes `covobjs` and `covpath` to `$GITHUB_ENV` without the required sanitization (`printf '%s' ... | tr -d '\n\r'`). These values are derived from shell commands that themselves use unsanitized `inputs.*`-derived env vars (`PACKAGE_PATH`, `BUILD_PARAMETERS`). A newline embedded in the value could inject arbitrary environment variables.

Step `convert-coverage-report` writes multiple `inputs.*`-derived env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, and many others) to `$GITHUB_OUTPUT` via `printf` without sanitization. While `printf` formats the values, none of the individual env var values are sanitized with `tr -d '\n\r'` before being embedded in the output, allowing newline injection into the output file.

Locations:

- `action.yml:74`
- `action.yml:75`
- `action.yml:107`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: Step `convert-coverage-report` uses `$(eval echo ${COVERAGE_OBJECTS})` — `eval` combined with command substitution (`$()`) and an unquoted variable. This matches the `eval-dynamic` pattern (`eval\s+[\x60$]`). The `COVERAGE_OBJECTS` variable is populated from shell command output in the previous step and written to `$GITHUB_ENV`, meaning its content is indirectly influenced by `inputs.*` values. An attacker could potentially inject shell commands via this eval.

Locations:

- `action.yml:98`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all three findings in hardened/action/action.yml:

1. script-injection: BUILD_PARAMETERS (list input) is now tokenized via xargs into a bash array `build_params` with quote-aware splitting. PACKAGE_PATH (single optional flag) uses `${PACKAGE_PATH:+"$PACKAGE_PATH"}`. The dangerous `$(eval echo ${COVERAGE_OBJECTS})` is replaced with a while-read loop building a `cov_obj_args` array.

2. github-env-injection: COVERAGE_OBJECTS is written to $GITHUB_ENV using multiline heredoc syntax with \r stripped. COVERAGE_DATA is sanitized with `tr -d '\n\r'`. All 19 input-derived values in convert-coverage-report are individually sanitized with `printf '%s' ... | tr -d '\n\r'` before being written to $GITHUB_OUTPUT.

3. suspicious-run-content: Removed `eval` entirely. Coverage objects are now stored as a newline-delimited list of plain paths in $GITHUB_ENV and consumed safely via a while-read loop that builds a properly quoted `--object "$obj_path"` argument array.

