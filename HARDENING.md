<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded **unquoted** in multiple shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the intended command and execute arbitrary code.

Locations:

- `action.yml:50`
- `action.yml:56`
- `action.yml:57`

### script-injection (severity: high)

Sub-rule (b): In the `convert-coverage-report` step, `${COVERAGE_OBJECTS}` is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})`. `COVERAGE_OBJECTS` is set from `$GITHUB_ENV` by the previous step, which itself was derived from `inputs.*`-controlled paths. The unquoted expansion inside `eval` allows shell metacharacters in the value to be interpreted, enabling command injection.

Locations:

- `action.yml:99`

### github-env-injection (severity: high)

In the `determine-package-info` step, `covobjs` and `covpath` are computed from `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (which hold `inputs.package_path` and `inputs.build_parameters` respectively) and then written directly to `$GITHUB_ENV` via `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline embedded in an input value can inject arbitrary environment variable definitions into subsequent steps.

Locations:

- `action.yml:69`
- `action.yml:70`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` (including `TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `BASE_SHA`, `CODECV_YML_PTH`, `DIS_FILE_FIXES`, `DISABLE_TELEM`, `DRY_RUN`, `ENV_VARS`, `FAIL_CI_IF_ERR`, `FLAGS`, `OVERRIDE_BRNCH`, `OVERRIDE_BUILD`, `OVERRIDE_B_URL`, `OVERRIDE_COMIT`, `OVERRIDE_PR`, `NAME`, `SWIFT_PROJECT`, `VERBOSE`) are written to `$GITHUB_OUTPUT` via `printf ... >>"${GITHUB_OUTPUT}"` without sanitizing newlines from the individual values first. A newline character in any of these inputs can inject additional key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting other outputs.

Locations:

- `action.yml:109`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all four findings in action.yml:

1. script-injection (determine-package-info step): BUILD_PARAMETERS is now tokenized with xargs into a bash array (build_params) using the guard+xargs+read-loop pattern. PACKAGE_PATH (a single flag) is placed into pkg_path_args array. Both are expanded with properly quoted array syntax '"${build_params[@]}"' and '"${pkg_path_args[@]}"' in all three swift commands.

2. script-injection (convert-coverage-report step): Removed the dangerous '$(eval echo ${COVERAGE_OBJECTS})'. Coverage objects are now stored as a newline-delimited list in GITHUB_ENV using GitHub Actions' multiline heredoc syntax (VAR<<DELIMITER\nvalue\nDELIMITER), then reconstructed in the convert step into a cov_obj_args bash array by reading line-by-line, and expanded safely as '"${cov_obj_args[@]}'".

3. github-env-injection (determine-package-info step): covpath is sanitized with 'printf \'%s\' "${covpath}" | tr -d \'\n\r\'' before writing to GITHUB_ENV. The covobjs_list uses GitHub Actions' multiline value syntax which avoids newline injection.

4. github-env-injection (convert-coverage-report step): All 19 env vars are individually sanitized with 'printf \'%s\' "${VAR}" | tr -d \'\n\r\'' before being used in the printf that writes to GITHUB_OUTPUT.

