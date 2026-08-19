<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.1** was hardened automatically. 5 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The step `upload-coverage-report` references `codecov/codecov-action@v5`, which uses a mutable version tag (`@v5`) instead of a pinned 40-character commit SHA. A tag can be silently moved to point to a different (potentially malicious) commit, enabling supply-chain attacks.

Locations:

- `action.yml:78`

### script-injection (severity: high)

Rule (b) violation in step `determine-package-info`: The env vars `${PACKAGE_PATH}` (from `inputs.package_path`) and `${BUILD_PARAMETERS}` (from `inputs.build_parameters`) are expanded **unquoted** inside shell commands: `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`, `swift package ${PACKAGE_PATH} describe`, and `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path`. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can inject arbitrary commands. All expansions of these untrusted env vars must be double-quoted.

Locations:

- `action.yml:43`
- `action.yml:44`
- `action.yml:47`

### script-injection (severity: high)

Rule (b) violation in step `convert-coverage-report`: The env var `${PACKAGE_PATH}` (from `inputs.package_path`) is used unquoted in the redirection `>"${PACKAGE_PATH}codecov.txt"`. While the outer quotes partially protect the suffix, the variable itself is not double-quoted, allowing path traversal or shell metacharacter injection from a crafted `inputs.package_path` value.

Locations:

- `action.yml:70`

### github-env-injection (severity: high)

Step `determine-package-info` writes values derived from `inputs.package_path` and `inputs.build_parameters` to `$GITHUB_ENV` without sanitization. The variables `${binpath}` and `${excname}` are computed from shell commands that consumed the unsanitized `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` env vars. A newline character embedded in these inputs could inject arbitrary environment variables into subsequent steps. The required sanitization (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent before both `echo "COVERAGE_OBJECT=..." >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=..." >> "${GITHUB_ENV}"` writes.

Locations:

- `action.yml:50`
- `action.yml:51`

### github-env-injection (severity: high)

Step `convert-coverage-report` writes multiple `inputs.*`-derived env vars (`TOKEN` from `inputs.codecov_token`, `PACKAGE_PATH` from `inputs.package_path`, `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, `DRY_RUN` from other inputs) directly to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. A newline in any of these input values could inject additional output variables or corrupt the output file.

Locations:

- `action.yml:72`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed all 5 findings in action.yml: (1) Pinned codecov/codecov-action@v5 to full commit SHA 0fb7174895f61a3b6b78fc075e0cd60383518dac with # v5 comment. (2) Fixed script-injection for PACKAGE_PATH by using ${PACKAGE_PATH:+"${PACKAGE_PATH}"} (conditional double-quoted expansion for a single --package-path=foo value) in all three swift commands. (3) Fixed script-injection for BUILD_PARAMETERS by tokenizing it into a bash array using xargs (quote-aware, handles quoted sub-commands) and expanding as "${build_params[@]}". (4) Fixed github-env-injection for GITHUB_ENV writes by sanitizing binpath/${excname} and covpath/default.profdata with printf '%s' ... | tr -d '\n\r' before echoing to GITHUB_ENV. (5) Fixed github-env-injection for GITHUB_OUTPUT writes by sanitizing all 8 input-derived values (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) with printf '%s' ... | tr -d '\n\r' before the printf to GITHUB_OUTPUT.

### Iteration 2

**Fixes applied:** unpinned-uses, missing-permissions

**Notes:**

Pinned all 5 distinct action references to full commit SHAs: actions/checkout@v4→11d5960a, vapor/swift-codecov-action@main→ec2b969b, maxim-lobanov/setup-xcode@v1→ed7a3b1f, compnerd/gha-setup-vsdevenv@main→452f99ef, compnerd/gha-setup-swift@main→eeda069c. Added top-level `permissions: contents: read` block to enforce least-privilege access. Original tags/branches preserved as inline comments for readability.

