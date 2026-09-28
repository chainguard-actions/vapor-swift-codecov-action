<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.6

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.6** was hardened automatically. 2 finding(s) were identified and resolved across 3 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — sourced from `inputs.package_path` and `inputs.build_parameters` via the `env:` block — are expanded **unquoted** inside the `run:` shell commands. For example: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` and `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the argument context and execute arbitrary commands. All expansions of these variables must be double-quoted: `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"`.

Locations:

- `action.yml:57`

### github-env-injection (severity: high)

Two unsanitized writes to GitHub special environment files are present:

(1) In the `determine-package-info` step, `covobjs` and `covpath` — values derived from swift tool invocations that themselves consume attacker-controlled `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — are written directly to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization step. A newline embedded in these values could inject arbitrary environment variables into subsequent steps.

(2) In the `convert-coverage-report` step, multiple env vars sourced from `inputs.*` (e.g., `${TOKEN}`, `${PACKAGE_PATH}`, `${ROOTDIR}`, `${BASE_SHA}`, and many others) are written to `$GITHUB_OUTPUT` via `printf` without sanitization. A newline in any of these values could inject additional output parameters.

Locations:

- `action.yml:75`
- `action.yml:126`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed two security findings in hardened/action/action.yml:

1. script-injection: Double-quoted ${PACKAGE_PATH} and ${BUILD_PARAMETERS} in all swift command invocations in the determine-package-info step (swift test, swift build, swift package). Previously unquoted expansions allowed shell metacharacter injection.

2. github-env-injection (two locations):
   - In determine-package-info step: Added sanitization of covobjs and covpath using `printf '%s' "${VAR}" | tr -d '\n\r'` before writing to $GITHUB_ENV.
   - In convert-coverage-report step: Added sanitization of all 19 env vars (TOKEN, PACKAGE_PATH, ROOTDIR, BASE_SHA, and all passthrough parameters) using `printf '%s' "${VAR}" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed the script-injection vulnerability in the `convert-coverage-report` step at line 113 of action.yml. Changed `$(eval echo ${COVERAGE_OBJECTS})` to `$(eval echo "${COVERAGE_OBJECTS}")`. The double quotes around `${COVERAGE_OBJECTS}` prevent shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) embedded in the value from being interpreted by the shell before eval processes them, while still allowing eval to strip the single quotes around the paths and produce the correct argument list for `llvm-cov show`.

### Iteration 3

**Fixes applied:** script-injection

**Notes:**

Replaced the unsafe `$(eval echo "${COVERAGE_OBJECTS}")` in the `convert-coverage-report` step with a safe xargs-based tokenization into a bash array. The new code uses `printf '%s' "${COVERAGE_OBJECTS}" | xargs printf '%s\0'` with a NUL-delimited read loop to safely split the space-separated `--object='path'` arguments into individual array elements, then expands them as `"${cov_args[@]}"`. This eliminates the eval-based command injection vulnerability while preserving correct argument splitting behavior. The guard `if [ -n "${COVERAGE_OBJECTS}" ]` prevents xargs from emitting an empty argument when the variable is empty.

