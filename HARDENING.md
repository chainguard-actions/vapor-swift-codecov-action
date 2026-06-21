<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **vapor--swift-codecov-action/v0.3.1** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The step `upload-coverage-report` references `codecov/codecov-action@v5`, which uses a mutable version tag rather than a pinned 40-character commit SHA. This means the action could be silently updated to a different (potentially malicious) version without any change to this file.

Locations:

- `action.yml:75`

### script-injection (severity: high)

Rule (b) violation — unquoted shell variable expansions of untrusted inputs. In the `determine-package-info` step, `${PACKAGE_PATH}` (derived from `inputs.package_path`) and `${BUILD_PARAMETERS}` (derived from `inputs.build_parameters`) are expanded without double-quotes in shell commands: `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, `swift package ${PACKAGE_PATH} describe`, and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can achieve command injection. In the `convert-coverage-report` step, `${PACKAGE_PATH}` is also used unquoted in the output redirect `>"${PACKAGE_PATH}codecov.txt"`.

Locations:

- `action.yml:42`
- `action.yml:43`
- `action.yml:48`
- `action.yml:64`

### github-env-injection (severity: high)

Unsanitized writes of untrusted input-derived values to GitHub special environment files. (1) In `determine-package-info`: `binpath` and `covpath` are computed from `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (both sourced from `inputs.*`) and written directly to `$GITHUB_ENV` via `echo` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. A newline embedded in an input value can inject arbitrary environment variables. (2) In `convert-coverage-report`: env vars `TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, and `DRY_RUN` — all sourced from `inputs.*` — are written to `$GITHUB_OUTPUT` via `printf` without sanitization. A newline in any of these values can inject additional output parameters.

Locations:

- `action.yml:50`
- `action.yml:51`
- `action.yml:71`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed three security findings in action.yml: (1) Pinned codecov/codecov-action@v5 to full commit SHA 0fb7174895f61a3b6b78fc075e0cd60383518dac with # v5 comment. (2) Fixed script injection by replacing unquoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS} with ${VAR:+"$VAR"} pattern — this drops the argument entirely when empty (preserving original behavior) and double-quotes it when present (preventing shell metacharacter injection). (3) Fixed github-env-injection by sanitizing all input-derived values with 'printf "%s" "$VAR" | tr -d "\n\r"' before writing to $GITHUB_ENV and $GITHUB_OUTPUT, preventing newline-based environment variable injection.

