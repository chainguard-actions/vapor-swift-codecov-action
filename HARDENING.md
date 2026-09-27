<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation: In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — sourced from `inputs.package_path` and `inputs.build_parameters` respectively — are expanded **unquoted** inside multiple shell commands: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, and `swift package ${PACKAGE_PATH} describe`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the intended argument context and execute arbitrary commands. All expansions of these vars must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:55`
- `action.yml:60`
- `action.yml:61`

### github-env-injection (severity: high)

In the `determine-package-info` step, the values `covobjs` and `covpath` are written to `$GITHUB_ENV` via `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"`. These values are derived from `swift` command outputs that incorporate `${PACKAGE_PATH}` (from `inputs.package_path`) and filesystem paths. No `printf '%s' ... | tr -d '\n\r'` sanitization is applied before the write. A newline embedded in the input can inject arbitrary key=value pairs into the runner's environment.

Locations:

- `action.yml:71`
- `action.yml:72`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, a `printf` statement writes a JSON blob containing many `inputs.*`-derived env vars (TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) directly to `$GITHUB_OUTPUT` without the required `tr -d '\n\r'` sanitization. A newline character embedded in any of these caller-controlled inputs can inject additional key=value pairs into the step output, potentially overwriting subsequent outputs or poisoning downstream steps.

Locations:

- `action.yml:101`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: In the `convert-coverage-report` step, the shell command `$(eval echo ${COVERAGE_OBJECTS})` is used to expand the `COVERAGE_OBJECTS` variable (which was set in `$GITHUB_ENV` by the previous step and may contain attacker-influenced path components). Using `eval` with a dynamically constructed string — especially one derived from untrusted input — allows arbitrary shell command execution if the value contains shell metacharacters or command substitutions. Matching pattern: `eval $(...)`.

Locations:

- `action.yml:99`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all four findings in action.yml:

1. **script-injection**: Replaced unquoted `${PACKAGE_PATH}` with `${PACKAGE_PATH:+"${PACKAGE_PATH}"}` (drops out when empty, quoted when present) in all three swift commands. Replaced unquoted `${BUILD_PARAMETERS}` with xargs-based tokenization into a `build_params` bash array, then expanded as `"${build_params[@]}"`.

2. **github-env-injection (lines 71-72)**: Added `printf '%s' ... | tr -d '\n\r'` sanitization for both `covobjs` and `covpath` before writing to `$GITHUB_ENV`.

3. **github-env-injection (line 101)**: Captured the printf output into a `params` variable, then sanitized with `tr -d '\n\r'` before appending to `$GITHUB_OUTPUT`.

4. **suspicious-run-content (eval, line 99)**: Replaced `$(eval echo ${COVERAGE_OBJECTS})` with xargs-based tokenization into a `cov_obj_args` bash array. Also changed the `covobjs` format from `--object='path'` (single-quoted, requiring eval) to `--object=path` (unquoted, safe for xargs tokenization). The array is expanded as `"${cov_obj_args[@]}"` in the llvm-cov command.

