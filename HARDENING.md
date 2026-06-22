<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — which hold values from `inputs.package_path` and `inputs.build_parameters` — are expanded unquoted inside shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` and `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can achieve command injection.

Locations:

- `action.yml:61`
- `action.yml:67`

### github-env-injection (severity: high)

In the `determine-package-info` step, `covobjs` and `covpath` are derived from user-controlled inputs (`inputs.package_path`, `inputs.build_parameters` via `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}`) and written directly to `$GITHUB_ENV` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline injected via these inputs can define arbitrary environment variables for subsequent steps.

Locations:

- `action.yml:79`
- `action.yml:80`

### script-injection (severity: high)

Sub-rule (b) + eval-dynamic: In the `convert-coverage-report` step, `$(eval echo ${COVERAGE_OBJECTS})` expands `COVERAGE_OBJECTS` unquoted inside an eval and command substitution. `COVERAGE_OBJECTS` was set in `$GITHUB_ENV` from user-controlled input in the prior step. This allows an attacker to inject arbitrary shell commands via `inputs.package_path` or `inputs.build_parameters`.

Locations:

- `action.yml:100`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` (TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are written to `$GITHUB_OUTPUT` via `printf` without the required sanitization step (`tr -d '\n\r'`). A newline in any of these values can inject arbitrary output variables.

Locations:

- `action.yml:103`

### suspicious-run-content (severity: high)

eval-dynamic: The `convert-coverage-report` step uses `$(eval echo ${COVERAGE_OBJECTS})` — matching the `eval $(...)`  pattern — to dynamically construct and execute shell arguments. `COVERAGE_OBJECTS` is sourced from `$GITHUB_ENV` which was populated from user-controlled inputs, making this a vector for dynamic code execution.

Locations:

- `action.yml:100`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings in action.yml: (1) Replaced unquoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS} expansions in swift commands with properly quoted bash arrays (pkg_args and build_args); (2) Sanitized covobjs and covpath with printf+tr before writing to GITHUB_ENV; (3) Replaced $(eval echo ${COVERAGE_OBJECTS}) with a safe bash array reconstruction using a while/read loop over newline-separated values; (4) Sanitized all 18 env-var-derived values with printf+tr before writing to GITHUB_OUTPUT.

