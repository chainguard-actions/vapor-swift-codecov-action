<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — populated from `inputs.package_path` and `inputs.build_parameters` respectively — are expanded **unquoted** inside shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` (line 54), `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` (line 60), and `swift package ${PACKAGE_PATH} describe` (line 61). An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) will be parsed by the shell, enabling command injection.

Locations:

- `action.yml:54`
- `action.yml:60`
- `action.yml:61`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `${COVERAGE_OBJECTS}` (an env var set from filesystem paths that incorporate the caller-controlled `inputs.package_path`) is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})` on line 104. The unquoted expansion allows word-splitting and glob expansion, and the surrounding `eval` further allows arbitrary shell command execution from any metacharacters embedded in the value.

Locations:

- `action.yml:104`

### suspicious-run-content (severity: high)

eval-dynamic: The `convert-coverage-report` step uses `$(eval echo ${COVERAGE_OBJECTS})` (line 104), which matches the `eval\s+[$]` pattern. `eval` is applied to a shell variable whose content is derived from filesystem paths built with caller-controlled inputs, enabling dynamic command construction and execution.

Locations:

- `action.yml:104`

### github-env-injection (severity: high)

The `determine-package-info` step writes `covobjs` and `covpath` to `$GITHUB_ENV` (lines 73–74) without the required `printf '%s' ... | tr -d '\n\r'` sanitization. Both variables are derived from shell commands that incorporate `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`). A newline embedded in either input value would allow an attacker to inject arbitrary environment variable definitions into `$GITHUB_ENV`, affecting subsequent steps.

Locations:

- `action.yml:73`
- `action.yml:74`

### github-env-injection (severity: high)

The `convert-coverage-report` step writes a `printf`-formatted string containing multiple `inputs.*`-derived env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) directly to `$GITHUB_OUTPUT` (line 113) without `tr -d '\n\r'` sanitization on any of those values. A newline in any input allows an attacker to inject additional key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting outputs consumed by downstream steps.

Locations:

- `action.yml:107`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection

**Notes:**

Fixed all 5 findings in action.yml:

1. **Script injection (lines 54, 60, 61)**: Replaced unquoted `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` with bash arrays. `pkg_args` uses `--package-path "$PACKAGE_PATH"` (quoted), `build_args` uses `read -ra build_args <<< "$BUILD_PARAMETERS"`. Swift commands now use `"${pkg_args[@]}"` and `"${build_args[@]}"`.

2. **Script injection + eval (line 104)**: Removed `$(eval echo ${COVERAGE_OBJECTS})` entirely. Coverage objects are now stored as a newline-delimited string in GITHUB_ENV via heredoc syntax. The convert step reads them with `while IFS= read -r obj` into a `cov_obj_args` array, expanded as `"${cov_obj_args[@]}"`.

3. **GitHub env injection (lines 73-74)**: COVERAGE_OBJECTS sanitized with `tr -d '\r'` and written via heredoc format; COVERAGE_DATA sanitized with `tr -d '\n\r'` before writing to GITHUB_ENV.

4. **GitHub output injection (line 107)**: All 19 input-derived env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are individually sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` before being written to GITHUB_OUTPUT.

