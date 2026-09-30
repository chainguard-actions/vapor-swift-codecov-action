<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `PACKAGE_PATH` (holding `inputs.package_path`) and `BUILD_PARAMETERS` (holding `inputs.build_parameters`) are expanded **unquoted** inside the `run:` shell script. Specifically: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) would be interpreted by the shell, enabling command injection.

Locations:

- `action.yml:50`
- `action.yml:56`
- `action.yml:57`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `COVERAGE_OBJECTS` (an env var set from attacker-influenced data in the previous step via `$GITHUB_ENV`) is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})`. The unquoted expansion allows shell metacharacter injection, and the `eval` further amplifies the risk by re-interpreting the expanded string as a shell command.

Locations:

- `action.yml:98`

### github-env-injection (severity: high)

In the `determine-package-info` step, `covobjs` and `covpath` — values derived from `PACKAGE_PATH` and `BUILD_PARAMETERS` (which hold `inputs.package_path` and `inputs.build_parameters`) — are written directly to `$GITHUB_ENV` via `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline character embedded in an attacker-controlled input could inject arbitrary environment variable definitions into subsequent steps.

Locations:

- `action.yml:69`
- `action.yml:70`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` (`TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `BASE_SHA`, `CODECV_YML_PTH`, `DIS_FILE_FIXES`, `DISABLE_TELEM`, `DRY_RUN`, `ENV_VARS`, `FAIL_CI_IF_ERR`, `FLAGS`, `OVERRIDE_BRNCH`, `OVERRIDE_BUILD`, `OVERRIDE_B_URL`, `OVERRIDE_COMIT`, `OVERRIDE_PR`, `NAME`, `SWIFT_PROJECT`, `VERBOSE`) are written to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline in any attacker-controlled input could inject arbitrary output variable definitions.

Locations:

- `action.yml:101`

### suspicious-run-content (severity: high)

`eval-dynamic`: The `convert-coverage-report` step uses `$(eval echo ${COVERAGE_OBJECTS})` — `eval` with a `$`-prefixed command substitution — to expand the `COVERAGE_OBJECTS` variable. This matches the `eval\s+[$]` pattern for dynamic eval execution. Since `COVERAGE_OBJECTS` is set from attacker-influenced data (derived from `inputs.package_path` and `inputs.build_parameters` via `$GITHUB_ENV`), this allows an attacker to inject and execute arbitrary shell commands.

Locations:

- `action.yml:98`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all 5 findings in action.yml:

1. **script-injection (determine-package-info step)**: PACKAGE_PATH is now expanded as `${PACKAGE_PATH:+"$PACKAGE_PATH"}` (quoted, drops out when empty). BUILD_PARAMETERS is tokenized with xargs into a bash array `build_params=()` and expanded as `"${build_params[@]}"` in all three swift commands (swift test, swift build, swift package).

2. **script-injection + suspicious-run-content (convert-coverage-report step)**: Eliminated `$(eval echo ${COVERAGE_OBJECTS})` entirely. Changed COVERAGE_OBJECTS format from space-separated `--object='path'` strings to newline-separated plain paths. In the convert step, a `while IFS= read -r obj_path` loop safely builds a `cov_obj_args=()` array with `--object="$obj_path"` entries, expanded as `"${cov_obj_args[@]}"`.

3. **github-env-injection (determine-package-info step)**: covobjs is sanitized with `tr -d '\r'` and written using multiline heredoc syntax (`COVERAGE_OBJECTS<<_COVOBJS_EOF_`) to safely store newline-separated paths. covpath is sanitized with `tr -d '\n\r'` before writing.

4. **github-env-injection (convert-coverage-report step)**: All 18 attacker-influenced env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are sanitized with `printf '%s' ... | tr -d '\n\r'` before being used in the printf that writes to $GITHUB_OUTPUT.

