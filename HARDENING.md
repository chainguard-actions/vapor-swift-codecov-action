<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.7

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.7** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b), step 'determine-package-info': the env vars PACKAGE_PATH (from inputs.package_path) and BUILD_PARAMETERS (from inputs.build_parameters) are expanded without double quotes inside command substitutions. Offending lines: `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")/default.profdata"`, `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"` and `pkgname="$(swift package ${PACKAGE_PATH} describe ...)"`. Fix: quote them, e.g. use `${PACKAGE_PATH:+"$PACKAGE_PATH"}` for the optional path, and pass the build parameters as a properly split, quoted array.

Locations:

- `action.yml:50`
- `action.yml:57`
- `action.yml:58`

### script-injection (severity: high)

Rule (b), step 'convert-coverage-report': `$(eval echo ${COVERAGE_OBJECTS}) \` expands COVERAGE_OBJECTS unquoted and passes it through eval. That value comes from GITHUB_ENV and from paths derived from the package-path input, so the calling workflow or an earlier step can control it. Shell metacharacters in it, such as $(...), ; or backticks, will run as commands. Fix: drop the eval and pass the object paths as a quoted bash array.

Locations:

- `action.yml:110`

### github-env-injection (severity: high)

Step 'determine-package-info' writes `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"`. Both values are built from swift output that depends on the untrusted inputs.package_path and inputs.build_parameters, and neither is passed through `printf '%s' ... | tr -d '\n\r'` before the write. A newline in the value would let an attacker inject extra environment variables.

Locations:

- `action.yml:80`
- `action.yml:81`

### github-env-injection (severity: high)

Step 'convert-coverage-report' writes a printf-built `params=...` line to $GITHUB_OUTPUT (`>>"${GITHUB_OUTPUT}"`). It is built from untrusted input-derived env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, FLAGS, NAME, OVERRIDE_*, ENV_VARS, etc.), and none is sanitized with `printf '%s' ... | tr -d '\n\r'` first. A newline in an input would let an attacker inject extra step outputs or alter the params JSON, which is passed via fromJSON into the codecov action's `with:`.

Locations:

- `action.yml:113`
- `action.yml:120`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

determine-package-info step: PACKAGE_PATH is now passed as ${PACKAGE_PATH:+"$PACKAGE_PATH"}. BUILD_PARAMETERS is split on whitespace into an array with read -r -d '' -a, which is the same split upstream's unquoted expansion did. Swift command output is captured before it is used. Coverage objects are collected in a bash array and written NUL-separated to a temp file in RUNNER_TEMP. The file's path goes to GITHUB_ENV as SWIFT_CODECOV_OBJECTS_FILE. COVERAGE_OBJECTS (same format as upstream, kept for compatibility), COVERAGE_DATA and SWIFT_CODECOV_OBJECTS_FILE all go through printf | tr -d '\n\r' before being written. convert-coverage-report step: removed the eval. The object list is read from the NUL-separated file into a quoted array of --object=PATH arguments for llvm-cov. The params JSON is built into a variable, newlines are stripped, and then it is written to GITHUB_OUTPUT.

