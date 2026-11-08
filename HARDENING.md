<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.2** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) is violated: the shell variables built from the inputs package_path and build_parameters are expanded without quotes. Lines: `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`, `swift package ${PACKAGE_PATH} describe ...` and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`. Because they are unquoted, the shell splits them on spaces and expands glob characters, so the value can turn into extra arguments. The fix is the guarded quoted form ${VAR:+"$VAR"}. If BUILD_PARAMETERS has to hold several flags, read it into a bash array first.

Locations:

- `action.yml:39`
- `action.yml:40`
- `action.yml:47`

### github-env-injection (severity: high)

Step determine-package-info writes COVERAGE_OBJECT and COVERAGE_DATA to $GITHUB_ENV without first passing them through printf '%s' ... | tr -d '\n\r'. Both values come from `swift build`/`swift test` output, and those commands receive the untrusted inputs package_path and build_parameters. Lines: `echo "COVERAGE_OBJECT=${binpath}/${excname}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}/default.profdata" >>"${GITHUB_ENV}"`.

Locations:

- `action.yml:50`
- `action.yml:51`

### github-env-injection (severity: high)

Step convert-coverage-report writes `params=...` to $GITHUB_OUTPUT using printf. The values come from the input-derived variables TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE and DRY_RUN (from inputs.codecov_token, package_path, flags, env_vars and others), and none of them has newlines stripped with tr -d '\n\r' first. A newline in an input could add extra outputs, and the JSON fields can also be injected because the values are not escaped.

Locations:

- `action.yml:72`

### unpinned-uses (severity: high)

A composite step uses an action by a mutable tag instead of a full commit SHA: `uses: codecov/codecov-action@v5`.

Locations:

- `action.yml:79`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection, unpinned-uses

**Notes:**

script-injection: PACKAGE_PATH (a single --package-path=... value) is now expanded as ${PACKAGE_PATH:+"$PACKAGE_PATH"}. BUILD_PARAMETERS is a list that upstream expanded as an unquoted env var. It is now split on whitespace into a bash array (read -r -d '' -a, inside an if [ -n ] guard) and expanded quoted. The swift test --show-codecov-path call now runs as its own step with '|| true' and then goes through dirname, which keeps upstream's behaviour of not failing on that command. github-env-injection: before COVERAGE_OBJECT and COVERAGE_DATA are written to GITHUB_ENV, newlines are stripped with printf | tr -d '\n\r'. The params JSON is now built from the raw inputs. Every value has control characters (including newlines) removed and backslashes and quotes escaped. fail_ci_if_error, verbose and dry_run are written as JSON true/false when they are exactly true or false, otherwise as escaped strings. unpinned-uses: codecov/codecov-action is pinned to 0fb7174895f61a3b6b78fc075e0cd60383518dac (v5).

