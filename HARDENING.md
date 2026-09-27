<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — sourced from `inputs.package_path` and `inputs.build_parameters` respectively — are expanded **unquoted** inside shell commands. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can inject arbitrary commands. Offending lines:
  - `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")/default.profdata"`
  - `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`
  - `pkgname="$(swift package ${PACKAGE_PATH} describe --type json | ...)"`
Fix: quote all expansions, e.g. `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`

Locations:

- `action.yml:62`
- `action.yml:69`
- `action.yml:70`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `$(eval echo ${COVERAGE_OBJECTS})` uses `eval` with an unquoted `${COVERAGE_OBJECTS}` variable. COVERAGE_OBJECTS was written to GITHUB_ENV from paths derived from user-controlled `inputs.package_path` and `inputs.build_parameters`. An attacker can craft input values that cause `eval` to execute arbitrary shell commands. Fix: avoid `eval` entirely, or at minimum quote the variable: `eval echo "${COVERAGE_OBJECTS}"`

Locations:

- `action.yml:101`

### github-env-injection (severity: high)

In the `determine-package-info` step, `covobjs` and `covpath` are written to `$GITHUB_ENV` without sanitization. These values are derived from `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (which hold `inputs.package_path` and `inputs.build_parameters`). A newline embedded in those inputs can inject additional environment variable definitions. The required sanitization (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent before the writes:
  - `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"`
  - `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"`

Locations:

- `action.yml:80`
- `action.yml:81`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` (TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) are written to `$GITHUB_OUTPUT` via `printf ... >>"${GITHUB_OUTPUT}"` without sanitization. A newline in any of these inputs can inject additional key=value pairs into GITHUB_OUTPUT, potentially overwriting subsequent step outputs. The required `tr -d '\n\r'` sanitization is absent.

Locations:

- `action.yml:113`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all four findings in hardened/action/action.yml:

1. script-injection (determine-package-info, lines 62/69/70): Quoted PACKAGE_PATH using ${PACKAGE_PATH:+"${PACKAGE_PATH}"} (drops out when empty, since it's a single --package-path=... flag). Tokenized BUILD_PARAMETERS (a list of flags) into a bash array via xargs for quote-aware splitting, then expanded as "${build_params[@]}" to preserve argument boundaries without injection.

2. script-injection (convert-coverage-report, line 101): Replaced `$(eval echo ${COVERAGE_OBJECTS})` with safe xargs-based tokenization of COVERAGE_OBJECTS into a cov_obj_args array, expanded as "${cov_obj_args[@]}". No eval required.

3. github-env-injection (determine-package-info, lines 80/81): Added `printf '%s' "${covobjs}" | tr -d '\n\r'` and `printf '%s' "${covpath}" | tr -d '\n\r'` sanitization before writing COVERAGE_OBJECTS and COVERAGE_DATA to $GITHUB_ENV.

4. github-env-injection (convert-coverage-report, line 113): Added `printf '%s' ... | tr -d '\n\r'` sanitization for all 19 input-derived variables (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) before writing the params output to $GITHUB_OUTPUT.

