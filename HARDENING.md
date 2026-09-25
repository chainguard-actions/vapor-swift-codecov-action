<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.1** was hardened automatically. 3 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The step `upload-coverage-report` references `codecov/codecov-action@v5`, which uses a mutable version tag (`v5`) rather than a pinned 40-character commit SHA. This means the action could be silently updated to a malicious version without any change to this file.

Locations:

- `action.yml:79`

### script-injection (severity: high)

Sub-rule (b): In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded **unquoted** inside shell commands: `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path` (line 39) and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` (line 47). An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can break out of the intended command and execute arbitrary code.

Locations:

- `action.yml:39`
- `action.yml:47`

### github-env-injection (severity: high)

Two unsanitized writes to special GitHub environment files are present:

(1) Lines 50–51 (`determine-package-info` step): `echo "COVERAGE_OBJECT=${binpath}/${excname}" >>"${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}/default.profdata" >>"${GITHUB_ENV}"` write values derived from `${PACKAGE_PATH}` (which comes from `inputs.package_path`) to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. A newline embedded in the input can inject arbitrary environment variable assignments.

(2) Line 76 (`convert-coverage-report` step): `printf 'params=...' "${TOKEN}" "${PACKAGE_PATH}" "${ROOTDIR}" "${FLAGS}" "${ENVVARS}" "${RAISEERR}" "${VERBOSE}" "${DRY_RUN}" >>"${GITHUB_OUTPUT}"` writes values derived from `inputs.codecov_token`, `inputs.package_path`, `inputs.flags`, `inputs.env_vars`, `inputs.fail_ci_if_error`, `inputs.verbose`, and `inputs.dry_run` to `$GITHUB_OUTPUT` without sanitization. A newline in any of these inputs can inject additional output variable assignments.

Locations:

- `action.yml:50`
- `action.yml:51`
- `action.yml:76`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed three high-severity findings in hardened/action/action.yml:

1. unpinned-uses: Pinned `codecov/codecov-action@v5` to full commit SHA `0fb7174895f61a3b6b78fc075e0cd60383518dac` with `# v5` comment.

2. script-injection: Replaced unquoted `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` expansions in swift commands with bash arrays populated via xargs-based tokenization (with required `if [ -n ... ]` guards). Arrays are expanded as `"${pkg_path_args[@]}"` and `"${build_param_args[@]}"` in all three swift invocations (swift build, swift package, swift test).

3. github-env-injection: (a) Values written to $GITHUB_ENV are now sanitized with `printf '%s' ... | tr -d '\n\r'` before writing. (b) The params string written to $GITHUB_OUTPUT is now built via `printf ... | tr -d '\n\r'` and written with `printf '%s'` to prevent newline injection.

