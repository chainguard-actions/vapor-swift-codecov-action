<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.1** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The composite action uses `codecov/codecov-action@v5`, which is pinned to a mutable tag (`v5`) rather than an immutable 40-character commit SHA. This means the referenced action can be silently changed by the upstream maintainer or an attacker who compromises the account, enabling supply-chain attacks.

Locations:

- `action.yml:83`

### script-injection (severity: high)

Rule (b) violation: In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded **unquoted** inside shell commands. Unquoted expansions allow an attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) to break out of the intended command and execute arbitrary code. Offending lines:
- `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"`
- `pkgname="$(swift package ${PACKAGE_PATH} describe --type json | perl ...)"`
- `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path)")"`
All three should use `"${PACKAGE_PATH}"` and `"${BUILD_PARAMETERS}"` (double-quoted).

Locations:

- `action.yml:41`
- `action.yml:42`
- `action.yml:47`

### github-env-injection (severity: high)

In the `convert-coverage-report` step, multiple env vars derived from action inputs (`TOKEN` from `inputs.codecov_token`, `PACKAGE_PATH` from `inputs.package_path`, `ROOTDIR`, `FLAGS`, `ENVVARS`, `RAISEERR`, `VERBOSE`, `DRY_RUN` from other inputs) are written directly to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`). A newline character embedded in any of these input values could inject additional key=value pairs into the output file, potentially overwriting other step outputs.

Locations:

- `action.yml:72`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed three security findings in hardened/action/action.yml:
1. unpinned-uses (line 83): Pinned `codecov/codecov-action@v5` to full SHA `0fb7174895f61a3b6b78fc075e0cd60383518dac` with `# v5` comment.
2. script-injection (lines 41, 42, 47): Added double-quotes around `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` in all three swift command invocations in the `determine-package-info` step.
3. github-env-injection (line 72): Added sanitization for all 8 input-derived values (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) written to $GITHUB_OUTPUT using `printf '%s' "${VAR}" | tr -d '\n\r'` to strip embedded newlines before writing.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection finding in the `determine-package-info` step of action.yml. The values `${binpath}/${excname}` and `${covpath}/default.profdata` are now sanitized with `printf '%s' "$VAR" | tr -d '\n\r'` before being written to `$GITHUB_ENV`. This matches the sanitization pattern already used in the `convert-coverage-report` step for `$GITHUB_OUTPUT` writes.

