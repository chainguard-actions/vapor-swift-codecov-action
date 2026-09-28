<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — which hold `inputs.package_path` and `inputs.build_parameters` respectively — are expanded **unquoted** inside shell commands. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) will be interpreted by the shell. Offending lines:
  `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")/default.profdata"`
  `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`
  `pkgname="$(swift package ${PACKAGE_PATH} describe --type json | ...)"`
All three expansions must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:50`
- `action.yml:56`
- `action.yml:57`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `${COVERAGE_OBJECTS}` is expanded **unquoted** inside `$(eval echo ${COVERAGE_OBJECTS})`. `COVERAGE_OBJECTS` was set in the previous step from data derived from `inputs.package_path` and `inputs.build_parameters` (attacker-controlled), and is passed through `eval` without quoting, enabling arbitrary command injection. The offending line: `$(eval echo ${COVERAGE_OBJECTS}) \`

Locations:

- `action.yml:99`

### github-env-injection (severity: high)

The `determine-package-info` step writes `covobjs` and `covpath` to `$GITHUB_ENV` without sanitization. Both values are derived from `${PACKAGE_PATH}` (holding `inputs.package_path`) and `${BUILD_PARAMETERS}` (holding `inputs.build_parameters`), which are attacker-controllable. A newline embedded in either input value would allow injecting arbitrary environment variable definitions into `$GITHUB_ENV`. The required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent before both writes:
  `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"`
  `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"`

Locations:

- `action.yml:69`
- `action.yml:70`

### github-env-injection (severity: high)

The `convert-coverage-report` step writes multiple `inputs.*`-derived env vars to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without sanitization. The env vars TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, and VERBOSE all hold values sourced from `inputs.*`. A newline in any of these values would allow injecting arbitrary key=value pairs into `$GITHUB_OUTPUT`. The required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent before the write.

Locations:

- `action.yml:102`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all four security findings in hardened/action/action.yml:

1. **script-injection (determine-package-info step)**: PACKAGE_PATH is now expanded with `${PACKAGE_PATH:+"$PACKAGE_PATH"}` (quoted conditional expansion). BUILD_PARAMETERS is tokenized into a bash array using xargs for quote-aware splitting (`while IFS= read -r -d '' t; do build_params+=("$t"); done < <(printf '%s' "$BUILD_PARAMETERS" | xargs printf '%s\0')`), then expanded as `"${build_params[@]}"`.

2. **script-injection (convert-coverage-report step)**: Removed `$(eval echo ${COVERAGE_OBJECTS})`. Coverage object paths are now stored as newline-separated plain strings in GITHUB_ENV using the heredoc multiline syntax, then read back into a bash array with a `while IFS= read -r line` loop and expanded as `"${cov_obj_args[@]}"`.

3. **github-env-injection (covobjs/covpath writes)**: Both values are now sanitized before writing to GITHUB_ENV. covpath uses `tr -d '\n\r'`; covobjs uses `tr -d '\r'` and is written using the `COVERAGE_OBJECTS<<__EOF__` heredoc format to safely handle multiline values.

4. **github-env-injection (GITHUB_OUTPUT write)**: Defined a `safe()` shell function that strips newlines/carriage returns, and wrapped every input-derived variable in `$(safe "...")` before interpolating into the printf format string written to GITHUB_OUTPUT.

