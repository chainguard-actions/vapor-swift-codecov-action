<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b): in step 'determine-package-info', the env vars PACKAGE_PATH and BUILD_PARAMETERS come from the inputs package_path and build_parameters. The script expands them without double quotes, so the shell splits and globs their contents: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`, `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` and `swift package ${PACKAGE_PATH} describe ...`. They do not use the guarded `${VAR:+"$VAR"}` form either.

Locations:

- `action.yml:50`
- `action.yml:56`
- `action.yml:57`

### script-injection (severity: high)

Sub-rule (b): in step 'convert-coverage-report', the line `$(eval echo ${COVERAGE_OBJECTS})` expands COVERAGE_OBJECTS without quotes and passes it through eval. The value comes in through the process environment (it is written to GITHUB_ENV by the earlier step, and the calling workflow can also set it), so the action does not control it. Shell metacharacters in the value, such as `$(...)`, backticks or `;`, would be run as commands.

Locations:

- `action.yml:99`

### github-env-injection (severity: high)

In step 'convert-coverage-report', input-derived env vars are written to $GITHUB_OUTPUT with no `printf '%s' ... | tr -d '\n\r'` sanitization. These are TOKEN (inputs.codecov_token), PACKAGE_PATH, ROOTDIR, BASE_SHA, FLAGS, NAME, OVERRIDE_* and the rest of the passthrough inputs, written via `printf 'params={...}' ... >>"${GITHUB_OUTPUT}"`. A newline in any input lets an attacker inject extra output lines or change `params`. The next step passes `params` through fromJSON as the `with:` inputs of codecov-action.

Locations:

- `action.yml:102`
- `action.yml:108`

### github-env-injection (severity: high)

In step 'determine-package-info', COVERAGE_OBJECTS and COVERAGE_DATA are written to $GITHUB_ENV without newline sanitization: `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"`. covobjs and covpath come from swift commands run with the untrusted PACKAGE_PATH and BUILD_PARAMETERS inputs, and covobjs also contains the package name, which comes from the package manifest. No `printf '%s' ... | tr -d '\n\r'` step is applied before the write.

Locations:

- `action.yml:69`
- `action.yml:70`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Step determine-package-info: PACKAGE_PATH is one '--package-path=...' value, so it is now passed as ${PACKAGE_PATH:+"$PACKAGE_PATH"}. BUILD_PARAMETERS is a list that upstream expanded unquoted from an env var. It is now split on whitespace into an array with a guarded 'read -r -d "" -a ... || true', and the array is expanded quoted, using a form that also works with set -u on bash 3.2. COVERAGE_OBJECTS and COVERAGE_DATA have CR and LF removed with tr -d before they are written to GITHUB_ENV. Step convert-coverage-report: '$(eval echo ${COVERAGE_OBJECTS})' is replaced by a guarded, quote-aware xargs split into an array. This keeps the --object='path' quoting but never runs anything from the value. Every value written into the params line of GITHUB_OUTPUT has CR and LF stripped before printf writes it, and the line now ends with a newline.

