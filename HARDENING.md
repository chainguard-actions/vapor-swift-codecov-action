<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded **unquoted** in shell commands on lines 60, 65, and 66. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can break out of the intended command and execute arbitrary code. Example offending lines: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` and `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`. In the `convert-coverage-report` step, `${COVERAGE_OBJECTS}` is also unquoted inside `$(eval echo ${COVERAGE_OBJECTS})` (line 113) and `${PACKAGE_PATH}` is unquoted in the output redirection path (line 114).

Locations:

- `action.yml:60`
- `action.yml:65`
- `action.yml:66`
- `action.yml:113`
- `action.yml:114`

### github-env-injection (severity: high)

In the `determine-package-info` step, `covobjs` and `covpath` — computed using user-controlled inputs (`PACKAGE_PATH` from `inputs.package_path`, `BUILD_PARAMETERS` from `inputs.build_parameters`) — are written to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization (lines 75–76). A newline embedded in an input value can inject arbitrary environment variables. In the `convert-coverage-report` step, multiple input-derived env vars (`TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `BASE_SHA`, and many others sourced from `inputs.*`) are written directly to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` (line 122) without newline sanitization, allowing output injection.

Locations:

- `action.yml:75`
- `action.yml:76`
- `action.yml:122`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: In the `convert-coverage-report` step (line 113), the run block contains `$(eval echo ${COVERAGE_OBJECTS})`. This matches the `eval\s+[\x60$]` pattern — `eval` is used with a command substitution (`$(...)`), and the argument `${COVERAGE_OBJECTS}` is an unquoted variable whose value is derived from user-controlled inputs. This allows dynamic construction and execution of shell commands, which can be exploited to run arbitrary code.

Locations:

- `action.yml:113`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, suspicious-run-content

**Notes:**

Fixed all three findings in action.yml:

1. script-injection: Replaced unquoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS} expansions (lines 60, 65, 66) with bash arrays built via `read -ra` and expanded as "${arr[@]}". Replaced `$(eval echo ${COVERAGE_OBJECTS})` (line 113) with a safe while-loop that builds a cov_args array from newline-separated paths. Double-quoted ${PACKAGE_PATH} in the output redirection (line 114).

2. github-env-injection: Added `printf '%s' ... | tr -d '\n\r'` sanitization for covobjs and covpath before writing to $GITHUB_ENV (lines 75-76). Added individual sanitization for all 18 input-derived env vars before writing to $GITHUB_OUTPUT (line 122).

3. suspicious-run-content: Completely eliminated the `eval` usage by restructuring COVERAGE_OBJECTS to store newline-separated plain paths and rebuilding --object arguments via a safe bash array in the convert-coverage-report step.

### Iteration 2

**Fixes applied:** unpinned-uses

**Notes:**

Replaced all 6 occurrences of `actions/checkout@v6` in `.github/workflows/test.yml` with the pinned SHA reference `actions/checkout@df4cb1c069e1874edd31b4311f1884172cec0e10 # v6`. The SHA was resolved via lookup_action_sha. This covers all five jobs (linux-containerized-toplevel, linux-containerized-subpath, macos-toplevel, macos-subpath, windows-toplevel, windows-subpath) that used the mutable tag reference.

