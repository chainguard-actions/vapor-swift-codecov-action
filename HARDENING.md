<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — sourced from `inputs.package_path` and `inputs.build_parameters` — are expanded **unquoted** inside the `run:` shell script. Unquoted expansions allow an attacker-controlled value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) to be interpreted by the shell, enabling command injection. Offending lines: `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")/default.profdata"` and `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`. These must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:60`
- `action.yml:64`

### github-env-injection (severity: high)

In the `determine-package-info` step, `COVERAGE_OBJECTS` (derived from `${PACKAGE_PATH}` / `inputs.package_path` and filesystem paths) and `COVERAGE_DATA` (derived from swift tool output seeded by `${PACKAGE_PATH}`) are written to `$GITHUB_ENV` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline embedded in the value could inject arbitrary environment variable assignments into subsequent steps. Offending lines: `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"`.

Locations:

- `action.yml:75`
- `action.yml:76`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: In the `convert-coverage-report` step, the run block contains `$(eval echo ${COVERAGE_OBJECTS})`. This uses `eval` with a `$()` command substitution (matching pattern `eval\s+[\x60$]`) on an unquoted variable whose value is written from a prior step via `$GITHUB_ENV`. An attacker who can influence `COVERAGE_OBJECTS` (e.g. via `inputs.package_path`) can inject arbitrary shell commands through the `eval`. Offending line: `$(eval echo ${COVERAGE_OBJECTS}) \`.

Locations:

- `action.yml:113`

### script-injection (severity: high)

Rule (b): In the `convert-coverage-report` step, `${PACKAGE_PATH}` (sourced from `inputs.package_path`) is expanded **unquoted** in the run block: `>"${PACKAGE_PATH}codecov.txt"`. An attacker-controlled value with shell metacharacters could redirect output to unintended locations or inject commands. Additionally, `${COVERAGE_OBJECTS}` is passed unquoted to `eval echo`, compounding the injection risk. All expansions of inputs-derived env vars must be double-quoted.

Locations:

- `action.yml:113`
- `action.yml:114`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, all `inputs.*`-derived env vars (`TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `BASE_SHA`, `CODECV_YML_PTH`, `DIS_FILE_FIXES`, `DISABLE_TELEM`, `DRY_RUN`, `ENV_VARS`, `FAIL_CI_IF_ERR`, `FLAGS`, `OVERRIDE_BRNCH`, `OVERRIDE_BUILD`, `OVERRIDE_B_URL`, `OVERRIDE_COMIT`, `OVERRIDE_PR`, `NAME`, `SWIFT_PROJECT`, `VERBOSE`) are written to `$GITHUB_OUTPUT` via `printf` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline embedded in any of these values could inject arbitrary key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting outputs consumed by downstream steps. Offending line: `>> "${GITHUB_OUTPUT}"`.

Locations:

- `action.yml:124`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all five findings in hardened/action/action.yml:

1. script-injection (determine-package-info, lines 60/64): Quoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS} in swift test and swift build invocations.

2. github-env-injection (determine-package-info, lines 75/76): Sanitized covobjs and covpath with `printf '%s' ... | tr -d '\n\r'` before writing to $GITHUB_ENV.

3. suspicious-run-content + script-injection (convert-coverage-report, lines 113/114): Replaced `$(eval echo ${COVERAGE_OBJECTS})` with a safe bash array built via `xargs printf '%s\0'` and a `while IFS= read -r -d '' t` loop (guarded by `[ -n "${COVERAGE_OBJECTS}" ]`). Also quoted `${PACKAGE_PATH}` in the output redirect.

4. github-env-injection (convert-coverage-report, line 124): All 19 input-derived env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are sanitized with `printf '%s' ... | tr -d '\n\r'` into safe_* variables before being written to $GITHUB_OUTPUT.

