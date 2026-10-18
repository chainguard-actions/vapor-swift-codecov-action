<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.2** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action uses `codecov/codecov-action@v5`, which is pinned to a mutable version tag rather than an immutable 40-character commit SHA. A tag can be silently moved to point to a different (potentially malicious) commit, enabling supply-chain attacks. It should be pinned to a full SHA, e.g. `codecov/codecov-action@<40-char-sha> # v5`.

Locations:

- `action.yml:74`

### script-injection (severity: high)

Sub-rule (b): In step `determine-package-info`, the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded **unquoted** in multiple shell commands:
- Line 41: `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`
- Line 42: `swift package ${PACKAGE_PATH} describe ...`
- Line 47: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`

Unquoted expansion allows an attacker-controlled input value containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) to break out of the intended command and execute arbitrary shell code. All expansions of these caller-controlled env vars must be double-quoted.

Locations:

- `action.yml:41`
- `action.yml:42`
- `action.yml:47`

### github-env-injection (severity: high)

Two steps write values derived from untrusted `inputs.*` to special GitHub environment files without the required sanitization (`printf '%s' ... | tr -d '\n\r'`):

(1) Step `determine-package-info` (lines 50–51): `binpath`, `excname`, and `covpath` are computed by running `swift build`/`swift test` with caller-controlled `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}`. The results are written directly to `$GITHUB_ENV` via `echo "COVERAGE_OBJECT=..." >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=..." >> "${GITHUB_ENV}"`. A newline embedded in the output could inject additional environment variable assignments.

(2) Step `convert-coverage-report` (lines 63–70): Multiple env vars sourced from `inputs.*` (`TOKEN`, `PACKAGE_PATH`, `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, `DRY_RUN`) are written to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without stripping newlines. A newline in any of these values could inject additional output variable assignments.

Locations:

- `action.yml:50`
- `action.yml:51`
- `action.yml:70`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed three findings in hardened/action/action.yml:

1. **unpinned-uses**: Pinned `codecov/codecov-action@v5` to full commit SHA `codecov/codecov-action@0fb7174895f61a3b6b78fc075e0cd60383518dac # v5`.

2. **script-injection**: In the `determine-package-info` step, `BUILD_PARAMETERS` (a list of flags) is now tokenized via xargs into a bash array `build_params` and expanded as `"${build_params[@]}"`. `PACKAGE_PATH` (a single optional flag) is expanded as `${PACKAGE_PATH:+"$PACKAGE_PATH"}` so it drops out when empty and is quoted when present. All three swift command invocations (build, package describe, test) now use these safe expansions.

3. **github-env-injection**: 
   - `COVERAGE_OBJECT` and `COVERAGE_DATA` values are captured into `safe_obj`/`safe_data` variables with `printf '%s' ... | tr -d '\n\r'` before being written to `$GITHUB_ENV`.
   - The `params` output in `convert-coverage-report` is captured via `$()` with the printf piped through `tr -d '\n\r'` to strip any embedded newlines before writing to `$GITHUB_OUTPUT`.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed lines 65-70 in action.yml by removing backslashes before double quotes in the format() expressions within the env block of the convert-coverage-report step. The backslash-escaped quotes (\"...\") were replaced with plain double quotes ("...") in all six env var definitions: ROOTDIR, RAISEERR, VERBOSE, DRY_RUN, FLAGS, and ENVVARS. The rest of the file was preserved unchanged.

