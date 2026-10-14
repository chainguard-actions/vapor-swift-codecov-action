<!-- markdownlint-disable -->

# Hardening Report: vapor--swift-codecov-action/v0.3.5

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **vapor--swift-codecov-action/v0.3.5** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the `determine-package-info` step: the env vars `${PACKAGE_PATH}` and `${BUILD_PARAMETERS}` — both sourced from `inputs.*` — are expanded **unquoted** inside shell commands. For example: `swift test ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-codecov-path` and `swift build ${PACKAGE_PATH} ${BUILD_PARAMETERS} --show-bin-path`. An attacker-controlled input value containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the intended command and execute arbitrary code. All expansions of workflow-controllable env vars must be double-quoted.

Locations:

- `action.yml:68`

### github-env-injection (severity: high)

The `determine-package-info` step writes `covobjs` and `covpath` to `$GITHUB_ENV` without sanitization. Both variables are derived from `inputs.package_path` and `inputs.build_parameters` (via `PACKAGE_PATH` and `BUILD_PARAMETERS` env vars). An attacker-controlled input containing newlines could inject arbitrary environment variable assignments into `$GITHUB_ENV`. The required sanitization step (`printf '%s' "$VAR" | tr -d '\n\r'`) is absent before the `echo "COVERAGE_OBJECTS=${covobjs}" >> "${GITHUB_ENV}"` and `echo "COVERAGE_DATA=${covpath}" >> "${GITHUB_ENV}"` writes.

Locations:

- `action.yml:83`
- `action.yml:84`

### script-injection (severity: high)

Rule (b) violation in the `convert-coverage-report` step: `${COVERAGE_OBJECTS}` — inherited from `$GITHUB_ENV` and ultimately derived from `inputs.package_path` / `inputs.build_parameters` — is expanded **unquoted** inside a command substitution: `$(eval echo ${COVERAGE_OBJECTS})`. This is doubly dangerous because `eval` is used, meaning any shell metacharacters in the value will be interpreted as shell code. This allows full command injection via attacker-controlled inputs.

Locations:

- `action.yml:113`

### github-env-injection (severity: high)

The `convert-coverage-report` step writes multiple `inputs.*`-derived env vars (TOKEN, ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) to `$GITHUB_OUTPUT` via `printf ... >> "${GITHUB_OUTPUT}"` without the required sanitization step (`printf '%s' ... | tr -d '\n\r'`). An attacker-controlled input containing newline characters could inject arbitrary key=value pairs into `$GITHUB_OUTPUT`, potentially overwriting outputs consumed by downstream steps.

Locations:

- `action.yml:120`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

Fixed all four findings in hardened/action/action.yml:

1. script-injection (determine-package-info step, line 68): PACKAGE_PATH (optional single flag) now uses ${PACKAGE_PATH:+"$PACKAGE_PATH"} so it drops out when empty and is quoted when present. BUILD_PARAMETERS (a list of flags) is tokenized into a bash array via xargs (quote-aware, handles quoted sub-commands) and expanded as "${build_params[@]}".

2. github-env-injection (determine-package-info step, lines 83-84): covpath is sanitized with tr -d '\n\r' before writing as a simple key=value. covobjs_list (which may be multi-line for the .so case) is written using the GITHUB_ENV heredoc format (KEY<<MARKER\nvalue\nMARKER) which is the correct safe mechanism for multi-line values.

3. script-injection (convert-coverage-report step, line 113): Replaced the dangerous $(eval echo ${COVERAGE_OBJECTS}) with reading the newline-separated COVERAGE_OBJECTS list into a bash array (cov_args) and passing "${cov_args[@]}" to llvm-cov show. No eval, no unquoted expansion.

4. github-env-injection (convert-coverage-report step, line 120): All 18 input-derived variables are individually sanitized with printf '%s' "$VAR" | tr -d '\n\r' into safe_* variables before being concatenated in the printf that writes params= to $GITHUB_OUTPUT.

### Iteration 1

**Fixes applied:** publish-gate

**Notes:**

Fixed 17 env variable expressions in action.yml (lines 92-108) where backslash-escaped double quotes (\\\" sequences) were incorrectly added inside format() expressions. The upstream code uses single-quoted format strings with plain double quotes like format(',"root_dir":"{0}"', ...) but the hardened version had introduced backslashes making them format(',\\"root_dir\\":\\"{0}\\"', ...) which would produce literal backslash characters in the output values. All affected env vars (ROOTDIR, BASE_SHA, CODECV_YML_PTH, DIS_FILE_FIXES, DISABLE_TELEM, DRY_RUN, ENV_VARS, FAIL_CI_IF_ERR, FLAGS, OVERRIDE_BRNCH, OVERRIDE_BUILD, OVERRIDE_B_URL, OVERRIDE_COMIT, OVERRIDE_PR, NAME, SWIFT_PROJECT, VERBOSE) have been corrected to use the upstream quoting style.

