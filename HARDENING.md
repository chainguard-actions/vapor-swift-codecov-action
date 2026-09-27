<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.2** was hardened automatically. 5 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The step 'upload-coverage-report' uses 'codecov/codecov-action@v5', which is a mutable tag reference rather than a pinned 40-character commit SHA. This allows the upstream repository to silently change the code that runs in this action, enabling supply-chain attacks.

Locations:

- `action.yml:75`

### script-injection (severity: high)

Sub-rule (b): In the 'determine-package-info' step, the env vars PACKAGE_PATH and BUILD_PARAMETERS are sourced from inputs.package_path and inputs.build_parameters respectively, then expanded unquoted inside the run: script (e.g. `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` and `swift package ${PACKAGE_PATH} describe ...` and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`). An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can achieve command injection. All expansions of these env vars must be double-quoted.

Locations:

- `action.yml:43`

### script-injection (severity: high)

Sub-rule (b): In the 'convert-coverage-report' step, the env var PACKAGE_PATH (sourced from inputs.package_path) is expanded unquoted in the llvm-cov command: `>${PACKAGE_PATH}codecov.txt`. An attacker-controlled value with shell metacharacters can achieve command injection. The expansion must be double-quoted.

Locations:

- `action.yml:62`

### github-env-injection (severity: high)

In the 'determine-package-info' step, the values written to $GITHUB_ENV are derived from untrusted inputs: COVERAGE_OBJECT is built from `${binpath}/${excname}` and COVERAGE_DATA from `${covpath}/default.profdata`, where binpath/covpath/excname are computed using PACKAGE_PATH and BUILD_PARAMETERS (both sourced from inputs.*). These values are written with plain `echo ... >> "${GITHUB_ENV}"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline injected via inputs could add arbitrary environment variables.

Locations:

- `action.yml:56`
- `action.yml:57`

### github-env-injection (severity: high)

In the 'convert-coverage-report' step, multiple values derived from inputs.* (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN — all sourced from inputs via env:) are written to $GITHUB_OUTPUT via `printf ... >> "${GITHUB_OUTPUT}"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline injected via any of these inputs could inject arbitrary output variables.

Locations:

- `action.yml:71`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all 5 findings in action.yml:
1. Pinned codecov/codecov-action@v5 to full SHA 0fb7174895f61a3b6b78fc075e0cd60383518dac.
2. Fixed script-injection in determine-package-info: BUILD_PARAMETERS (a list input) is now tokenized via xargs into a bash array and expanded as "${build_params[@]}"; PACKAGE_PATH (a single --package-path=value flag) uses ${PACKAGE_PATH:+"$PACKAGE_PATH"} to safely pass it only when non-empty.
3. Fixed script-injection in convert-coverage-report: PACKAGE_PATH is now double-quoted in >"${PACKAGE_PATH}codecov.txt".
4. Fixed github-env-injection in determine-package-info: binpath/excname/covpath-derived values are sanitized with printf '%s' ... | tr -d '\n\r' before being written to $GITHUB_ENV.
5. Fixed github-env-injection in convert-coverage-report: all env-var-derived values (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) are sanitized with tr -d '\n\r' before being written to $GITHUB_OUTPUT.

