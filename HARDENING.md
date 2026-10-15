<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In step `determine-package-info`, the env vars `PACKAGE_PATH` and `BUILD_PARAMETERS` are sourced from `inputs.package_path` and `inputs.build_parameters` respectively, but are used **unquoted** in the `run:` block in multiple places: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can break out of the intended command and execute arbitrary shell code.

Locations:

- `action.yml:50`
- `action.yml:55`
- `action.yml:56`

### script-injection (severity: high)

Sub-rule (b) + eval-dynamic: In step `convert-coverage-report`, the expression `$(eval echo ${COVERAGE_OBJECTS})` uses `eval` with an unquoted variable. `COVERAGE_OBJECTS` was set in `$GITHUB_ENV` by the previous step using data derived from `inputs.*`-controlled variables. An attacker-controlled input value can inject arbitrary shell commands through the unquoted `eval` expansion. This is also a `suspicious-run-content` eval-dynamic pattern (`eval $(...)`).

Locations:

- `action.yml:96`

### github-env-injection (severity: high)

In step `determine-package-info`, the variables `covobjs` and `covpath` are computed from command output that uses `inputs.*`-sourced env vars (`PACKAGE_PATH`, `BUILD_PARAMETERS`). Both are written to `$GITHUB_ENV` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline embedded in the value could inject additional environment variable assignments: `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"`.

Locations:

- `action.yml:66`
- `action.yml:67`

### github-env-injection (severity: high)

In step `convert-coverage-report`, multiple env vars sourced directly from `inputs.*` (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are written to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without sanitization. A newline in any input value could inject additional key=value pairs into GITHUB_OUTPUT, allowing an attacker to override subsequent step outputs.

Locations:

- `action.yml:99`
- `action.yml:106`

### suspicious-run-content (severity: high)

eval-dynamic: In step `convert-coverage-report`, the run block contains `$(eval echo ${COVERAGE_OBJECTS})` which uses `eval` with a command substitution (`$(...)`). `COVERAGE_OBJECTS` is an env var set from workflow-controlled data (derived from `inputs.*`). This matches the `eval $(...)`/`eval \`...\`` pattern used to dynamically construct and execute shell commands, and can be exploited to run arbitrary code if the input is attacker-controlled.

Locations:

- `action.yml:96`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings in action.yml:

1. **script-injection (PACKAGE_PATH/BUILD_PARAMETERS)**: Replaced unquoted `${PACKAGE_PATH} ${BUILD_PARAMETERS}` expansions with proper bash arrays tokenized via the xargs idiom. Each variable is now split into `pkg_path_args` and `build_param_args` arrays and passed as `"${pkg_path_args[@]}"` and `"${build_param_args[@]}"` to swift commands.

2. **script-injection + suspicious-run-content (eval echo ${COVERAGE_OBJECTS})**: Completely eliminated `eval`. Coverage objects are now stored in GITHUB_ENV as typed data: `COVERAGE_OBJ_TYPE` (bundle/single/multi), `COVERAGE_OBJ_PATH` (for single/bundle), or `COVERAGE_OBJ_PATHS_B64` (base64-encoded newline-separated paths for multi). The convert-coverage-report step reconstructs a proper bash array `cov_obj_args` without any eval.

3. **github-env-injection (covpath/covobjs to GITHUB_ENV)**: All values written to GITHUB_ENV are now sanitized with `printf '%s' "$var" | tr -d '\n\r'` before writing.

4. **github-env-injection (multiple vars to GITHUB_OUTPUT)**: All 18 input-derived variables (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, etc.) are sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` before being used in the printf that writes to GITHUB_OUTPUT.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed 17 env variable lines in action.yml (lines 107-123) in the convert-coverage-report step. The previous hardening pass had incorrectly escaped the double quotes inside format() string arguments by adding backslashes (changing '"root_dir"' to '\"root_dir\"'), which caused the values to contain literal backslash characters. Restored the original upstream quoting by removing the erroneous backslashes, so format strings like format(',\"root_dir\":\"{0}\"', ...) are now correctly format(',"root_dir":"{0}"', ...) — i.e., single-quoted format strings containing unescaped double quotes.

