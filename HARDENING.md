<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.4

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.4** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in step 'determine-package-info'. The env vars PACKAGE_PATH and BUILD_PARAMETERS hold values from inputs.package_path and inputs.build_parameters, but the script expands them without double quotes. They are not written in the guarded ${VAR:+"$VAR"} form either. Example lines: `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")/default.profdata"`, `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"` and `swift package ${PACKAGE_PATH} describe ...`.

Locations:

- `action.yml:53`

### script-injection (severity: high)

Rule (b) violation in step 'convert-coverage-report': `$(eval echo ${COVERAGE_OBJECTS})`. COVERAGE_OBJECTS comes from the previous step through GITHUB_ENV, and it is built from binpath (shaped by input-controlled swift flags) and pkgname (taken from the repository's package manifest). The value is expanded without quotes and then passed through eval, so shell metacharacters in it are run as commands. Because composite actions inherit env from the calling workflow, a caller can also set COVERAGE_OBJECTS directly.

Locations:

- `action.yml:101`

### github-env-injection (severity: high)

Step 'determine-package-info' writes values to $GITHUB_ENV without first running them through `printf '%s' ... | tr -d '\n\r'`: `echo "COVERAGE_OBJECTS=${covobjs}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >>"${GITHUB_ENV}"`. Both values come from swift output that depends on inputs.package_path and inputs.build_parameters, and on the repository-controlled package name. A newline in either value could inject extra environment variables.

Locations:

- `action.yml:75`

### github-env-injection (severity: high)

Step 'convert-coverage-report' writes `params=...` to $GITHUB_OUTPUT using a printf that embeds many input-derived env vars: TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, FLAGS, NAME, OVERRIDE_* and others, all from inputs.*. None of them is cleaned with `tr -d '\n\r'` before the write, so a newline in any input could inject extra step outputs. Those outputs then feed fromJSON in the upload step.

Locations:

- `action.yml:104`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

determine-package-info: PACKAGE_PATH (one value, '--package-path=...') is now expanded as ${PACKAGE_PATH:+"$PACKAGE_PATH"}. BUILD_PARAMETERS is a list that upstream expanded unquoted from env, so it is now split on whitespace into an array with `read -r -d '' -a` and expanded quoted. Coverage object paths are written one per line to a mktemp file under RUNNER_TEMP. Only that file's path (SWIFT_CODECOV_OBJECTS_FILE) and COVERAGE_DATA go to GITHUB_ENV, both with newlines stripped (tr -d '\n\r'). convert-coverage-report: replaced `$(eval echo ${COVERAGE_OBJECTS})` with an array of quoted --object=<path> arguments read from that file, and the xcrun/llvm-cov prefix is now an array too. The params JSON is built into a variable, its newlines are stripped, and then it is written to GITHUB_OUTPUT.

