<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: In step `determine-package-info`, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (sourced from `inputs.package_path` and `inputs.build_parameters` via the `env:` block) are expanded **unquoted** inside shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input value containing shell metacharacters (`;`, `|`, `$(...)`, etc.) would be interpreted by the shell, enabling command injection.

Locations:

- `action.yml:63`
- `action.yml:68`
- `action.yml:69`

### script-injection (severity: high)

Rule (b) violation: In step `convert-coverage-report`, the env var `${COVERAGE_OBJECTS}` (written to $GITHUB_ENV from shell-computed values in the prior step, which itself used unsanitized inputs) is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})`. Additionally, `${PACKAGE_PATH}` (sourced from `inputs.package_path`) is used unquoted in the output redirect `>"${PACKAGE_PATH}codecov.txt"`. Unquoted expansions allow shell metacharacter injection.

Locations:

- `action.yml:107`
- `action.yml:108`

### suspicious-run-content (severity: high)

eval-dynamic: The `convert-coverage-report` step uses `$(eval echo ${COVERAGE_OBJECTS})` — `eval` combined with command substitution (`$(...)`). This matches the `eval\s+[\x60$]` pattern for dynamic eval execution. The `COVERAGE_OBJECTS` variable is constructed from shell-computed paths in the prior step and then dynamically evaluated, which can execute arbitrary shell commands if the value is attacker-influenced.

Locations:

- `action.yml:107`

### github-env-injection (severity: high)

In step `determine-package-info`, the values `covobjs` and `covpath` — computed by running `swift test`/`swift build`/`swift package` with unsanitized `inputs.package_path` and `inputs.build_parameters` — are written directly to `$GITHUB_ENV` via `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. A newline embedded in these values could inject additional environment variables.

Locations:

- `action.yml:79`
- `action.yml:80`

### github-env-injection (severity: high)

In step `convert-coverage-report`, multiple env vars derived from `inputs.*` (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are written to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. An attacker-controlled input containing a newline could inject arbitrary key=value pairs into GITHUB_OUTPUT, poisoning subsequent steps.

Locations:

- `action.yml:116`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection

**Notes:**

Rewrote action.yml to fix all five findings:

1. **script-injection (determine-package-info step)**: Replaced unquoted `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` expansions with xargs-tokenized bash arrays (`pkg_path_args` and `build_param_args`), expanded as `"${pkg_path_args[@]}"` in all swift commands.

2. **script-injection + suspicious-run-content (convert-coverage-report step)**: Eliminated `$(eval echo ${COVERAGE_OBJECTS})` entirely. Coverage objects are now stored as individually-indexed env vars (`COVERAGE_OBJECT_0`, `COVERAGE_OBJECT_1`, `COVERAGE_OBJECTS_COUNT`) in GITHUB_ENV and reconstructed into a bash array in the next step. `PACKAGE_PATH` is now properly double-quoted in the output redirect.

3. **github-env-injection (determine-package-info step)**: Each coverage object path and `covpath` are sanitized with `printf '%s' ... | tr -d '\n\r'` before being written to `$GITHUB_ENV`.

4. **github-env-injection (convert-coverage-report step)**: All 19 input-derived env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, etc.) are individually sanitized with `printf '%s' ... | tr -d '\n\r'` before being used in the printf that writes to `$GITHUB_OUTPUT`.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed lines 99-115 of action.yml: removed backslashes before double quotes inside format() strings in the env block of the convert-coverage-report step. The hardened version had incorrectly escaped the double quotes as \" (literal backslash-quote) inside single-quoted format strings like format(',\"root_dir\":\"{0}\"', ...), but the correct upstream form uses plain double quotes: format(',"root_dir":"{0}"', ...). All 17 affected env var lines (ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) were corrected.

