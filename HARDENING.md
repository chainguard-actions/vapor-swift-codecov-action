<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — which hold values derived from `inputs.package_path` and `inputs.build_parameters` — are expanded **unquoted** inside the `run:` shell script. Unquoted expansions allow shell metacharacters (`;`, `|`, `&`, `$(...)`, whitespace, globs) embedded in the input values to be interpreted by the shell, enabling command injection. Affected lines: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. All three should use `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"` with double quotes.

Locations:

- `action.yml:68`
- `action.yml:76`
- `action.yml:77`

### script-injection (severity: high)

Sub-rule (b): In the `convert-coverage-report` step, `${COVERAGE_OBJECTS}` is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})`. `COVERAGE_OBJECTS` is an inherited env var (set via `$GITHUB_ENV` in the prior step) whose value is derived from filesystem paths influenced by `inputs.package_path` and `inputs.build_parameters`. The unquoted expansion inside `eval` allows shell metacharacters in the value to be interpreted, enabling command injection. The offending line is: `$(eval echo ${COVERAGE_OBJECTS})`.

Locations:

- `action.yml:113`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: The `convert-coverage-report` step uses `$(eval echo ${COVERAGE_OBJECTS})` — `eval` combined with a `$()` command substitution and an unquoted variable. This matches the `eval\s+[\x60$]` pattern for dynamically constructed and executed shell commands. The `COVERAGE_OBJECTS` env var is set from filesystem-derived data influenced by user-controlled inputs, making this a potential code execution vector.

Locations:

- `action.yml:113`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` values (`TOKEN`, `ROOTDIR`, `BASE_SHA`, `CODECV_YML_PTH`, `DIS_FILE_FIXES`, `DISABLE_TELEM`, `DRY_RUN`, `ENV_VARS`, `FAIL_CI_IF_ERR`, `FLAGS`, `OVERRIDE_BRNCH`, `OVERRIDE_BUILD`, `OVERRIDE_B_URL`, `OVERRIDE_COMIT`, `OVERRIDE_PR`, `NAME`, `SWIFT_PROJECT`, `VERBOSE`, `PACKAGE_PATH`) are written to `$GITHUB_OUTPUT` via `printf` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). An attacker-controlled input containing a newline character could inject additional key=value pairs into `$GITHUB_OUTPUT`, potentially overriding subsequent step outputs or injecting arbitrary data consumed by the `upload-coverage-report` step via `fromJSON(steps.convert-coverage-report.outputs.params)`.

Locations:

- `action.yml:116`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection

**Notes:**

Fixed all four findings in hardened/action/action.yml:

1. Script injection (determine-package-info step): BUILD_PARAMETERS is now tokenized into a bash array using the xargs/read-loop idiom (handles quoted arguments safely). PACKAGE_PATH uses ${PACKAGE_PATH:+"$PACKAGE_PATH"} since it's a single optional flag. All three swift commands (test, build, package) now use "${build_params[@]}" and properly quoted PACKAGE_PATH.

2. Script injection + suspicious-run-content (convert-coverage-report step): Completely removed $(eval echo ${COVERAGE_OBJECTS}). COVERAGE_OBJECTS is now stored as newline-separated paths (without embedded single quotes) using GITHUB_ENV heredoc syntax (COVERAGE_OBJECTS<<EOF_COVOBJS). In convert-coverage-report, paths are read line-by-line into a cov_obj_args array with --object= prefix, then passed as "${cov_obj_args[@]}" to llvm-cov.

3. GitHub env injection (convert-coverage-report step): All 19 input-derived variables (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are sanitized with printf '%s' "$VAR" | tr -d '\n\r' before being written to $GITHUB_OUTPUT.

