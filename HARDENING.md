<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.3** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded **unquoted** inside multiple shell commands. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the intended command and execute arbitrary code. Offending lines:
- `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`
- `pkgname="$(swift package ${PACKAGE_PATH} describe --type json | ...)"`
- `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")"`
Fix: quote every expansion — `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:39`
- `action.yml:40`
- `action.yml:42`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from `inputs.*` — `TOKEN` (`inputs.codecov_token`), `PACKAGE_PATH` (`inputs.package_path`), `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, `DRY_RUN` — are written directly to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required newline-stripping sanitization (`printf '%s' "$VAR" | tr -d '\n\r'`). A value containing a newline can inject arbitrary key=value pairs into the output, potentially overwriting other step outputs or poisoning downstream steps. Fix: sanitize each value with `tr -d '\n\r'` before writing to `$GITHUB_OUTPUT`.

Locations:

- `action.yml:70`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed two high-severity findings in hardened/action/action.yml:
1. script-injection: Quoted all ${PACKAGE_PATH} and ${BUILD_PARAMETERS} expansions in the `determine-package-info` step's shell commands. Changed `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS}`, `swift package ${PACKAGE_PATH}`, and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS}` to use double-quoted expansions `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"` to prevent shell metacharacter injection.
2. github-env-injection: Added newline-stripping sanitization for all 8 env vars (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) in the `convert-coverage-report` step before writing to $GITHUB_OUTPUT. Each value is now sanitized with `printf '%s' "${VAR}" | tr -d '\n\r'` and stored in a SAFE_* variable before being passed to the printf that writes to $GITHUB_OUTPUT.

