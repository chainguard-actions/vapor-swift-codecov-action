<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **vapor--swift-codecov-action/v0.3.3** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — both sourced from `inputs.package_path` and `inputs.build_parameters` respectively — are expanded **unquoted** inside the `run:` shell commands. For example: `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"` and `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")"`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) would be interpreted by the shell, enabling command injection.

Locations:

- `action.yml:40`
- `action.yml:43`

### script-injection (severity: high)

Sub-rule (b): In the `convert-coverage-report` step, the env vars `${ROOTDIR}`, `${FLAGS}`, `${ENVVARS}`, `${RAISEERR}`, `${VERBOSE}`, and `${DRY_RUN}` — all sourced from `inputs.*` — are passed **unquoted** as arguments to `printf`: `"${ROOTDIR}" "${FLAGS}" "${ENVVARS}" "${RAISEERR}" "${VERBOSE}" "${DRY_RUN}"`. While they appear inside a `printf` format-argument position, they are unquoted shell expansions and can be split or interpreted by the shell before printf receives them.

Locations:

- `action.yml:71`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` — `TOKEN` (`inputs.codecov_token`), `PACKAGE_PATH` (`inputs.package_path`), `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, `DRY_RUN` — are written directly to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). A newline character embedded in any of these inputs could inject additional key=value pairs into the output file, potentially overwriting subsequent step outputs.

Locations:

- `action.yml:67`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed three findings in action.yml:
1. script-injection (determine-package-info, lines 40/43): Changed unquoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS} expansions to use ${VAR:+"$VAR"} form. This drops the argument entirely when the variable is empty (preserving original behavior) and double-quotes the value when present (preventing shell metacharacter injection).
2. script-injection (convert-coverage-report, line 71): All printf arguments (ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) are now sanitized into safe_* variables and properly double-quoted in the printf call.
3. github-env-injection (convert-coverage-report, line 67): Added sanitization of all input-derived variables (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) using `printf '%s' "$VAR" | tr -d '\n\r'` before they are used in the printf that writes to $GITHUB_OUTPUT, preventing newline injection that could overwrite subsequent step outputs.

