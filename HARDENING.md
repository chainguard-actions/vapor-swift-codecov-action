<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In step `determine-package-info`, the env vars `PACKAGE_PATH` and `BUILD_PARAMETERS` are sourced from `inputs.package_path` and `inputs.build_parameters` respectively, but are expanded **unquoted** inside the `run:` shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, backticks, etc.) would be interpreted by the shell, enabling command injection.

Locations:

- `action.yml:62`
- `action.yml:68`
- `action.yml:69`

### script-injection (severity: high)

Sub-rule (b): In step `convert-coverage-report`, the expression `$(eval echo ${COVERAGE_OBJECTS})` expands `COVERAGE_OBJECTS` unquoted inside `eval echo`. `COVERAGE_OBJECTS` was written to `$GITHUB_ENV` in the previous step and is derived from `PACKAGE_PATH` (which comes from `inputs.package_path`). An attacker-controlled value in `COVERAGE_OBJECTS` could inject arbitrary shell commands via the unquoted `eval` expansion.

Locations:

- `action.yml:107`

### suspicious-run-content (severity: high)

eval-dynamic: In step `convert-coverage-report`, the run block uses `$(eval echo ${COVERAGE_OBJECTS})` — `eval` with a command substitution/variable expansion. `COVERAGE_OBJECTS` is a workflow-environment-controlled value (set via `$GITHUB_ENV` from a prior step that processes user inputs), making this a dynamic eval of potentially attacker-influenced content. Matching pattern: `eval\s+[\x60$]`.

Locations:

- `action.yml:107`

### github-env-injection (severity: high)

In step `determine-package-info`, two values are written to `$GITHUB_ENV` without sanitization: `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"`. Both `covobjs` and `covpath` are derived from shell commands that use `PACKAGE_PATH` (sourced from `inputs.package_path`) and `BUILD_PARAMETERS` (sourced from `inputs.build_parameters`). A newline injected via these inputs could add arbitrary environment variable definitions. The required sanitization (`printf '%s' ... | tr -d '\n\r'`) is absent.

Locations:

- `action.yml:79`
- `action.yml:80`

### github-env-injection (severity: high)

In step `convert-coverage-report`, the `printf` command writes multiple input-derived env vars — including TOKEN (`inputs.codecov_token`), PACKAGE_PATH (`inputs.package_path`), ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE — directly to `$GITHUB_OUTPUT` without the required `tr -d '\n\r'` sanitization. A newline embedded in any of these inputs could inject additional output variable definitions.

Locations:

- `action.yml:110`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection

**Notes:**

Fixed all 5 findings in hardened/action/action.yml:

1. **script-injection (determine-package-info, lines 62/68/69)**: Replaced unquoted `${PACKAGE_PATH} ${BUILD_PARAMETERS}` expansions in swift commands with properly tokenized bash arrays. BUILD_PARAMETERS is tokenized via xargs into `build_params_args` (handles multiple flags like `-c release`); PACKAGE_PATH goes into `pkg_path_args`. Both are expanded as `"${arr[@]}"` in the swift test/build/package commands.

2. **script-injection + suspicious-run-content (convert-coverage-report, line 107)**: Replaced `$(eval echo ${COVERAGE_OBJECTS})` with safe xargs-based tokenization into `cov_obj_args` array, expanded as `"${cov_obj_args[@]}"`. No eval needed.

3. **github-env-injection (determine-package-info, lines 79/80)**: Added `printf '%s' ... | tr -d '\n\r'` sanitization for `covobjs` and `covpath` before writing to `$GITHUB_ENV`.

4. **github-env-injection (convert-coverage-report, line 110)**: Added `printf '%s' ... | tr -d '\n\r'` sanitization for all 19 input-derived values (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, and 15 passthrough params) before writing to `$GITHUB_OUTPUT`. The printf format string itself uses only literal strings so no injection is possible there.

