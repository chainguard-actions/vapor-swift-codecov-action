<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Sub-rule (b), unquoted expansion of input-derived env vars, in step 'determine-package-info'. PACKAGE_PATH and BUILD_PARAMETERS come from inputs.package_path and inputs.build_parameters and are expanded without quotes, so the shell word-splits and glob-expands them: `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")/default.profdata"`. The same happens on lines 56–57: `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` and `swift package ${PACKAGE_PATH} describe`.

Locations:

- `action.yml:50`
- `action.yml:56`
- `action.yml:57`

### script-injection (severity: high)

Sub-rule (b), unquoted expansion run through eval, in step 'convert-coverage-report'. `$(eval echo ${COVERAGE_OBJECTS})` expands COVERAGE_OBJECTS without quotes and evaluates it. That value comes from $GITHUB_ENV, set in the previous step from paths built out of inputs.package_path and inputs.build_parameters. Any shell metacharacters in it, or in the binpath/pkgname it was built from, would be run as commands.

Locations:

- `action.yml:99`

### github-env-injection (severity: high)

Step 'determine-package-info' writes values derived from untrusted input to $GITHUB_ENV without the `printf '%s' ... | tr -d '\n\r'` sanitization. The lines are `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"`. covobjs and covpath are built from swift output driven by inputs.package_path and inputs.build_parameters (via PACKAGE_PATH and BUILD_PARAMETERS), and from package metadata. A newline in either value would let someone inject extra environment variables.

Locations:

- `action.yml:69`
- `action.yml:70`

### github-env-injection (severity: high)

Step 'convert-coverage-report' writes many input-derived env vars to $GITHUB_OUTPUT without newline sanitization: `printf 'params={...}' "${TOKEN}" "${PACKAGE_PATH}" "${ROOTDIR}" ... >>"${GITHUB_OUTPUT}"`. The values come from inputs.codecov_token, package_path, base_sha, flags, name, override_* and other inputs. A newline in any of them would let someone inject extra step outputs. That matters here because the next step feeds this output straight into fromJSON for the codecov action's `with:` inputs.

Locations:

- `action.yml:102`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

All changes are in action.yml. Nothing was run to test them.

- **determine-package-info:** PACKAGE_PATH is one optional value, so it is now passed as ${PACKAGE_PATH:+"$PACKAGE_PATH"}. BUILD_PARAMETERS is a list that upstream expanded unquoted, so it is now split on whitespace into an array (`read -r -d '' -a ... || true`) and passed as "${build_args[@]}". The swift test output is now saved to a variable before dirname runs on it, so a failing swift test still stops the step.
- **Coverage objects:** these are now collected as an array of plain paths instead of a string with embedded single quotes. COVERAGE_OBJECTS is written to GITHUB_ENV as a multi-line value, one path per line, inside a random delimiter made from /dev/urandom. CR/LF is removed from each path. COVERAGE_DATA has CR/LF removed before it is written.
- **convert-coverage-report:** the `eval echo` is gone. COVERAGE_OBJECTS is read line by line into an array of --object=<path> arguments that is passed to llvm-cov with quotes.
- **params JSON:** it is now built into a variable first, then CR/LF is stripped before `params=...` is written to GITHUB_OUTPUT.

One small difference from upstream: the params line now ends with a newline. GitHub reads the output the same way.

