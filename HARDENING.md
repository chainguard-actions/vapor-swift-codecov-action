<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.7** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) — Unquoted shell variable expansion of untrusted data in the `determine-package-info` step. The env vars `${PACKAGE_PATH}` (from `inputs.package_path`) and `${BUILD_PARAMETERS}` (from `inputs.build_parameters`) are expanded unquoted in multiple `swift` commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can achieve command injection.

Locations:

- `action.yml:62`
- `action.yml:69`
- `action.yml:70`

### script-injection (severity: high)

Rule (b) — Unquoted shell variable expansion of untrusted data in the `convert-coverage-report` step. `${COVERAGE_OBJECTS}` (an inherited env var set from untrusted `inputs.*`-derived data in the previous step) is expanded unquoted inside `$(eval echo ${COVERAGE_OBJECTS})`, and `${PACKAGE_PATH}` (from `inputs.package_path`) is expanded unquoted in the output redirect `>"${PACKAGE_PATH}codecov.txt"`. Both allow shell metacharacter injection.

Locations:

- `action.yml:121`
- `action.yml:122`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: The `convert-coverage-report` step uses `$(eval echo ${COVERAGE_OBJECTS})` — `eval` with command substitution (`$(...)`). `COVERAGE_OBJECTS` is an env var set from filesystem paths influenced by untrusted `inputs.package_path` and `inputs.build_parameters`. This pattern dynamically constructs and executes shell commands and matches the `eval $(...)`/eval-dynamic failing pattern.

Locations:

- `action.yml:121`

### github-env-injection (severity: high)

The `determine-package-info` step writes `covobjs` and `covpath` to `$GITHUB_ENV` without sanitization (`printf '%s' ... | tr -d '\n\r'`). Both variables are derived from `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}`, which hold values from `inputs.package_path` and `inputs.build_parameters` respectively. A newline injected via these inputs can add arbitrary environment variables or PATH entries for subsequent steps.

Locations:

- `action.yml:88`
- `action.yml:89`

### github-env-injection (severity: high)

The `convert-coverage-report` step writes multiple `inputs.*`-derived env vars (`${TOKEN}`, `${PACKAGE_PATH}`, `${ROOTDIR}`, `${BASE_SHA}`, and many others) to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without sanitization (`printf '%s' ... | tr -d '\n\r'`). A newline embedded in any of these input values can inject additional output parameters that downstream steps consume.

Locations:

- `action.yml:124`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection

**Notes:**

Fixed all 5 findings in action.yml:

1. script-injection (determine-package-info step): Tokenized PACKAGE_PATH and BUILD_PARAMETERS into bash arrays using the xargs/NUL-separated read loop pattern. Swift commands now use '"${pkg_path_args[@]}"' and '"${build_param_args[@]}"' instead of unquoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS}.

2. script-injection + suspicious-run-content (convert-coverage-report step): Eliminated 'eval echo ${COVERAGE_OBJECTS}' entirely. Coverage objects are now stored as a base64-encoded NUL-separated list in GITHUB_ENV and deserialized into a bash array in the next step. The array is expanded as '"${covobjs_args[@]}"'. PACKAGE_PATH in the output redirect is now properly quoted.

3. github-env-injection (determine-package-info step): COVERAGE_OBJECTS and COVERAGE_DATA are sanitized with 'tr -d '\n\r'' before writing to $GITHUB_ENV.

4. github-env-injection (convert-coverage-report step): All 19 input-derived variables (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, and all passthrough parameters) are sanitized with 'printf '%s' "${VAR}" | tr -d '\n\r'' before being written to $GITHUB_OUTPUT.

