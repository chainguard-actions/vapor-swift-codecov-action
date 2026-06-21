<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **vapor--swift-codecov-action/v0.3.2** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The `uses:` reference `codecov/codecov-action@v5` in action.yml uses a mutable version tag instead of a pinned 40-character commit SHA. This is vulnerable to supply-chain attacks if the tag is moved to a different (potentially malicious) commit.

Locations:

- `action.yml:83`

### script-injection (severity: high)

Rule (b) violation: In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — populated from `inputs.package_path` and `inputs.build_parameters` respectively — are expanded unquoted inside shell command strings. Unquoted expansion allows an attacker to inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) via those inputs. Affected lines:
- Line 43: `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`
- Line 44: `pkgname="$(swift package ${PACKAGE_PATH} describe ...)"`
- Line 51: `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")"`
All occurrences of `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:43`
- `action.yml:44`
- `action.yml:51`

### github-env-injection (severity: high)

Multiple writes to special GitHub environment files use values derived from user-controlled inputs without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`):

1. In `determine-package-info` (lines 54-55): `binpath` and `covpath` are computed using `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` (from `inputs.package_path` and `inputs.build_parameters`) and written directly to `$GITHUB_ENV` via `echo`. A newline in the input can inject arbitrary environment variable assignments.

2. In `convert-coverage-report` (line 80): The `printf` statement writes `${TOKEN}`, `${PACKAGE_PATH}`, `${ROOTDIR}`, `${FLAGS}`, `${ENVVARS}`, `${RAISEERR}`, `${VERBOSE}`, and `${DRY_RUN}` — all derived from user-supplied inputs — to `$GITHUB_OUTPUT` without sanitization. A newline in any of these values can inject arbitrary output variable assignments.

Locations:

- `action.yml:54`
- `action.yml:55`
- `action.yml:80`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all three high-severity findings in action.yml:
1. unpinned-uses: Pinned `codecov/codecov-action@v5` to full commit SHA `0fb7174895f61a3b6b78fc075e0cd60383518dac` with `# v5` comment for readability.
2. script-injection: Double-quoted all unquoted expansions of `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` in the `determine-package-info` step shell commands (swift build, swift package, and swift test invocations).
3. github-env-injection: Added `printf '%s' ... | tr -d '\n\r'` sanitization for all user-controlled values before writing to $GITHUB_ENV (COVERAGE_OBJECT and COVERAGE_DATA) and $GITHUB_OUTPUT (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN).

