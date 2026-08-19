<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.3** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` hold values sourced from `inputs.package_path` and `inputs.build_parameters` respectively, but are expanded **unquoted** inside shell commands. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) would be interpreted by the shell. Offending lines:
  - `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`
  - `pkgname="$(swift package ${PACKAGE_PATH} describe ...)"`
  - `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")"`

Locations:

- `action.yml:43`
- `action.yml:44`
- `action.yml:46`

### github-env-injection (severity: high)

In the `determine-package-info` step, `COVERAGE_OBJECT` and `COVERAGE_DATA` are written to `$GITHUB_ENV` without sanitization (`printf '%s' ... | tr -d '\n\r'`). The values are derived from shell variables (`${binpath}`, `${excname}`, `${covpath}`) that are themselves computed from the unsanitized `inputs.package_path` and `inputs.build_parameters` env vars. A newline injected via these inputs could add arbitrary environment variables for subsequent steps.

Locations:

- `action.yml:48`
- `action.yml:49`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: multiple env vars holding `inputs.*` values are expanded **unquoted** in shell commands. `${PACKAGE_PATH}` is unquoted in the output redirect `>"${PACKAGE_PATH}codecov.txt"`. `${ROOTDIR}`, `${FLAGS}`, `${ENVVARS}`, `${RAISEERR}`, `${VERBOSE}`, and `${DRY_RUN}` are all passed unquoted as arguments to `printf`. An attacker-controlled input containing shell metacharacters would be interpreted by the shell.

Locations:

- `action.yml:68`
- `action.yml:71`
- `action.yml:72`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, the output of `printf` — which embeds multiple unsanitized `inputs.*`-derived env vars (`TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, `DRY_RUN`) — is written directly to `$GITHUB_OUTPUT` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). A newline character in any of these inputs could inject additional key=value pairs into the GitHub output context.

Locations:

- `action.yml:73`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all four findings in hardened/action/action.yml:

1. script-injection (determine-package-info, lines 43-46): PACKAGE_PATH (a single optional flag '--package-path=VALUE') is now expanded with ${PACKAGE_PATH:+"$PACKAGE_PATH"} so it drops out when empty and is quoted when present. BUILD_PARAMETERS (a whitespace-separated list of flags) is tokenized via xargs into a bash array (build_params) using the quote-aware xargs pattern, then expanded as "${build_params[@]}" — preventing shell metacharacter injection from either input.

2. github-env-injection (determine-package-info, lines 48-49): COVERAGE_OBJECT and COVERAGE_DATA are now sanitized with `printf '%s' ... | tr -d '\n\r'` before being written to $GITHUB_ENV, preventing newline injection.

3. script-injection (convert-coverage-report, lines 68-72): PACKAGE_PATH in the output redirect is now quoted as "${PACKAGE_PATH}codecov.txt". All printf arguments (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) are now double-quoted.

4. github-env-injection (convert-coverage-report, line 73): The printf output is captured into raw_params, then sanitized with `printf '%s' "${raw_params}" | tr -d '\n\r'` into safe_params before being written to $GITHUB_OUTPUT, preventing newline injection.

### Iteration 2

**Fixes applied:** unpinned-uses

**Notes:**

Replaced all 6 occurrences of `actions/checkout@v6` in `.github/workflows/test.yml` with the pinned SHA reference `actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6`. The SHA was resolved using lookup_action_sha. The other action references (maxim-lobanov/setup-xcode and compnerd/gha-setup-swift) were already SHA-pinned and required no changes.

