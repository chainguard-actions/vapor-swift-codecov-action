<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.2

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.2** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

The step `upload-coverage-report` references `codecov/codecov-action@v5`, which uses a mutable version tag instead of a pinned 40-character commit SHA. This exposes the workflow to supply-chain attacks if the tag is moved to a different (potentially malicious) commit.

Locations:

- `action.yml:80`

### script-injection (severity: high)

Rule (b) violation: In the `determine-package-info` step, the env vars `${PACKAGE_PATH}` (sourced from `inputs.package_path`) and `${BUILD_PARAMETERS}` (sourced from `inputs.build_parameters`) are expanded unquoted inside `run:` shell commands. An attacker-controlled input containing shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) can achieve command injection. Offending lines include:
- `binpath="$(swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path)"` (line 41)
- `pkgname="$(swift package ${PACKAGE_PATH} describe ...)"` (line 42)
- `covpath="$(dirname "$(swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} ...)"` (line 47)

In the `convert-coverage-report` step, `${PACKAGE_PATH}` is also used unquoted in a file redirect: `> "${PACKAGE_PATH}codecov.txt"` (line 71).

Locations:

- `action.yml:41`
- `action.yml:42`
- `action.yml:47`
- `action.yml:71`

### github-env-injection (severity: high)

Two unsanitized writes to GitHub special environment files are present:

1. In the `determine-package-info` step (lines 50–51), `${binpath}` and `${covpath}` — derived from shell commands that consume untrusted `inputs.package_path` and `inputs.build_parameters` — are written to `$GITHUB_ENV` without the required `printf '%s' ... | tr -d '\n\r'` sanitization. A newline embedded in these values could inject arbitrary environment variables into subsequent steps.

2. In the `convert-coverage-report` step (lines 73–76), a `printf` statement writes values derived from `inputs.*` (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) directly to `$GITHUB_OUTPUT` without sanitization. A newline in any of these inputs could inject additional output variables.

Locations:

- `action.yml:50`
- `action.yml:51`
- `action.yml:73`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, github-env-injection

**Notes:**

Fixed three security findings in hardened/action/action.yml:

1. unpinned-uses: Pinned `codecov/codecov-action@v5` to full commit SHA `0fb7174895f61a3b6b78fc075e0cd60383518dac` with `# v5` comment.

2. script-injection: (a) BUILD_PARAMETERS is now tokenized into a bash array using the xargs/read-loop idiom to safely handle multiple flags while preventing shell metacharacter injection. (b) PACKAGE_PATH (a single flag value) is now expanded with `${PACKAGE_PATH:+"$PACKAGE_PATH"}` to safely handle the empty-string default while quoting the value when present. All three unquoted usages in swift build/package/test commands are fixed.

3. github-env-injection: (a) binpath and covpath values derived from swift command output are sanitized with `printf '%s' ... | tr -d '\n\r'` before writing to $GITHUB_ENV. (b) All eight input-derived values (TOKEN, PACKAGE_PATH, ROOTDIR, FLAGS, ENVVARS, RAISEERR, VERBOSE, DRY_RUN) are individually sanitized before being assembled into the printf output written to $GITHUB_OUTPUT.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed lines 65-70 in action.yml by replacing backslash-escaped double quotes (\" ) with plain double quotes (") in the format() expressions within the env block of the convert-coverage-report step. The backslashes were literal text in YAML that changed the values from what upstream intended, causing downstream tools (like yq) to fail with 'Can't handle character' errors. The six affected env vars are: ROOTDIR, RAISEERR, VERBOSE, DRY_RUN, FLAGS, and ENVVARS.

