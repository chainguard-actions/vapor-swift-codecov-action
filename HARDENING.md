<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The step 'upload-coverage-report' uses 'codecov/codecov-action@v5', which is pinned to a mutable tag ('v5') rather than an immutable 40-character commit SHA. This means the action could be silently replaced with a malicious version without any change to the workflow file.

Locations:

- `action.yml:79`

### script-injection (severity: high)

Sub-rule (b): In the 'determine-package-info' step, the env vars ${PACKAGE_PATH} and ${BUILD_PARAMETERS} — which hold values derived from inputs.package_path and inputs.build_parameters respectively — are expanded unquoted inside shell commands. For example: `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` and `swift package ${PACKAGE_PATH} describe ...` and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can achieve command injection. All expansions of these variables must be double-quoted.

Locations:

- `action.yml:44`

### github-env-injection (severity: high)

Two unsanitized writes to special GitHub environment files are present:

(1) In the 'determine-package-info' step, the values ${binpath} and ${covpath} — computed by running swift commands that incorporate the unsanitized, attacker-controlled ${PACKAGE_PATH} and ${BUILD_PARAMETERS} inputs — are written directly to $GITHUB_ENV without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. A newline embedded in these values can inject arbitrary environment variables into subsequent steps.

(2) In the 'convert-coverage-report' step, multiple env vars derived from inputs (TOKEN from inputs.codecov_token, PACKAGE_PATH from inputs.package_path, ROOTDIR/FLAGS/ENVVARS/RAISEERR/VERBOSE/DRY_RUN from other inputs) are written directly to $GITHUB_OUTPUT via `printf ... >> "${GITHUB_OUTPUT}"` without sanitization. Newlines in any of these values can inject arbitrary output variables.

Locations:

- `action.yml:57`
- `action.yml:58`
- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed three security findings in hardened/action/action.yml:

1. **unpinned-uses**: Pinned `codecov/codecov-action@v5` to the full commit SHA `0fb7174895f61a3b6b78fc075e0cd60383518dac` with a `# v5` comment for readability.

2. **script-injection**: Changed all unquoted `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` expansions in the `determine-package-info` step's shell commands to use the `${VAR:+"$VAR"}` pattern. This double-quotes the values when non-empty (preventing shell metacharacter injection) and omits them entirely when empty (avoiding empty-argument issues with optional flags).

3. **github-env-injection**: 
   - In `determine-package-info`: Added `safe_coverage_object` and `safe_coverage_data` variables that sanitize the computed paths using `printf '%s' ... | tr -d '\n\r'` before writing to `$GITHUB_ENV`.
   - In `convert-coverage-report`: Added sanitization for all 8 env vars (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) using `printf '%s' ... | tr -d '\n\r'` before using them in the `printf` call that writes to `$GITHUB_OUTPUT`.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed lines 59-64 in action.yml by removing backslashes before double quotes in the format() expressions for ROOTDIR, RAISEERR, VERBOSE, DRY_RUN, FLAGS, and ENVVARS env vars. The previous code had \"root_dir\" (backslash-escaped quotes) which produced literal backslashes in the string values, breaking downstream JSON parsing. The corrected code uses plain double quotes inside single-quoted format strings: format(',"root_dir":"{0}"', ...) which produces the correct JSON fragment ,"root_dir":"value" without any backslashes.

