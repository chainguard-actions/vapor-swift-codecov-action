<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — sourced from `inputs.package_path` and `inputs.build_parameters` respectively — are expanded **unquoted** inside shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) will be parsed by the shell, enabling command injection. All three expansions must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:62`

### script-injection (severity: high)

Rule (b) violation: In the `convert-coverage-report` step, `${COVERAGE_OBJECTS}` is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})`. `COVERAGE_OBJECTS` is an inherited env var written to `$GITHUB_ENV` in the previous step from attacker-influenced paths (derived from `inputs.package_path` and `inputs.build_parameters`). The unquoted expansion inside `eval` allows shell metacharacter injection. Additionally, `eval` with `$()` command substitution matches the `eval-dynamic` suspicious pattern.

Locations:

- `action.yml:100`

### github-env-injection (severity: high)

In the `determine-package-info` step, `COVERAGE_OBJECTS` and `COVERAGE_DATA` are written to `$GITHUB_ENV` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). `COVERAGE_OBJECTS` is constructed from `${binpath}` and `${pkgname}`, which are derived from `PACKAGE_PATH` (sourced from `inputs.package_path`) and `BUILD_PARAMETERS` (sourced from `inputs.build_parameters`). A newline embedded in these attacker-controlled inputs could inject arbitrary environment variables into `$GITHUB_ENV`. The writes `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"` must be preceded by sanitization.

Locations:

- `action.yml:72`
- `action.yml:73`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, the `printf` command writes a value derived from multiple `inputs.*`-sourced env vars (TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) directly to `$GITHUB_OUTPUT` without sanitization. A newline in any of these attacker-controlled inputs could inject additional key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting other step outputs. The `printf ... >> "${GITHUB_OUTPUT}"` write must be preceded by sanitizing each variable with `printf '%s' "$VAR" | tr -d '\n\r'`.

Locations:

- `action.yml:108`

### suspicious-run-content (severity: high)

eval-dynamic: In the `convert-coverage-report` step, the run block contains `$(eval echo ${COVERAGE_OBJECTS})` — `eval` is used with `$()` command substitution, matching the `eval\s+[$]` pattern. This dynamically constructs and executes shell commands from the contents of `COVERAGE_OBJECTS`, which is an inherited env var derived from attacker-influenced inputs. This is an obfuscation-capable pattern that can execute arbitrary shell commands if `COVERAGE_OBJECTS` contains shell metacharacters.

Locations:

- `action.yml:100`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings in action.yml:

1. script-injection (line 62): BUILD_PARAMETERS is now tokenized via xargs into a bash array `build_params` for quote-aware splitting without shell evaluation. PACKAGE_PATH uses `${PACKAGE_PATH:+"$PACKAGE_PATH"}` so it drops out when empty and is properly quoted when present. All three swift commands (swift test, swift build, swift package) now use `"${build_params[@]}"` and `${PACKAGE_PATH:+"$PACKAGE_PATH"}`.

2. script-injection (line 100) + suspicious-run-content (line 100): Replaced `$(eval echo ${COVERAGE_OBJECTS})` with a proper bash array `obj_flags` built by reading COVERAGE_OBJECTS line by line. No eval is used anywhere.

3. github-env-injection (lines 72-73): covpath is sanitized with `tr -d '\r'` before writing to GITHUB_ENV. covobjs is written using GitHub's multiline heredoc syntax (`COVERAGE_OBJECTS<<__COVOBJS_EOF__`) which correctly handles multi-line values without newline injection risk.

4. github-env-injection (line 108): All 19 input-derived variables are sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` before being used in the printf that writes to GITHUB_OUTPUT.

The COVERAGE_OBJECTS format was changed from shell-quoted `--object='path'` strings to newline-separated plain paths, eliminating the need for eval in the consuming step.

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed the incomplete sanitization of `safe_covpath` in the `determine-package-info` step. Changed `tr -d '\r'` to `tr -d '\n\r'` so that both newlines and carriage returns are stripped from the coverage path before it is written to `$GITHUB_ENV` via `echo "COVERAGE_DATA=${safe_covpath}" >> "${GITHUB_ENV}"`. This prevents a crafted input from injecting arbitrary environment variables into subsequent steps.

