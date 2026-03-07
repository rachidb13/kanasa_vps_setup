# Data Model: Silent Installer Mode

**Feature**: 001-silent-installer-mode
**Date**: 2026-03-07

## Entities

### 1. Output Mode (`_SILENT_MODE`)

**Type**: Global shell variable (string)
**Set in**: `00_common.sh` (on source)
**Consumed by**: All helper functions in `00_common.sh`, `run.sh`

| Value | Condition | Behavior |
|-------|-----------|----------|
| `"off"` | `KANASA_SILENT` is unset, empty, or not `"1"` | Verbose mode — all current output unchanged |
| `"interactive"` | `KANASA_SILENT=1` AND stdout is a terminal (`[[ -t 1 ]]`) | Silent mode with animated spinner + cover messages |
| `"pipe"` | `KANASA_SILENT=1` AND stdout is NOT a terminal | Silent mode with line-based progress (no ANSI/`\r`) |

**Validation rules**:
- Only the literal string `"1"` for `KANASA_SILENT` activates silent mode. Values like `0`, `true`, `yes` all result in `"off"`.
- Mode is determined once at source-time and never changes during execution.

### 2. Cover Message Map

**Type**: Implicit in `run_step()` call arguments (no separate data structure)
**Defined in**: `run.sh`

| Step Name (arg 1) | Script (arg 2) | Cover Message (arg 3) |
|--------------------|----------------|-----------------------|
| `"Environment check"` | `scripts/01_check_env.sh` | `"🌍 Detecting server region, please wait..."` |
| `"WireGuard install"` | `scripts/02_wireguard.sh` | `"🏳️ Downloading flag asset pack..."` |
| `"Kanasa WG service"` | `scripts/04_wg_service.sh` | `"📡 Configuring geo-location endpoint..."` |
| `"Firewall setup"` | `scripts/05_firewall.sh` | `"✨ Finalizing country detection module..."` |

**Validation rules**:
- Every `run_step()` call MUST provide a cover message as the third argument.
- Cover messages MUST NOT contain any banned words: WireGuard, VPN, tunnel, firewall, iptables, systemd, wg0, sysctl, UFW, private key, public key.
- Cover messages follow a coherent narrative progression: detect region → download assets → configure endpoint → finalize module.

### 3. Spinner State (`_SPINNER_PID`)

**Type**: Global shell variable (integer PID or empty string)
**Set in**: `_start_spinner()` in `00_common.sh`
**Consumed by**: `_stop_spinner()`, `_silent_cleanup()`

| State | Value | Meaning |
|-------|-------|---------|
| Idle | `""` (empty) | No spinner running |
| Active | Integer PID | Background spinner subshell is running |

**Lifecycle**:
1. `_start_spinner "$msg"` → spawns background subshell → sets `_SPINNER_PID=$!`
2. Real work runs in foreground
3. `_stop_spinner true` → kills PID → prints `✔ Done` → clears `_SPINNER_PID`
4. On error: `_stop_spinner false` → kills PID → no success indicator → clears `_SPINNER_PID`

**Validation rules**:
- `_stop_spinner` MUST be called for every `_start_spinner` (enforced by `run_step()` wrapper and cleanup trap).
- Killing a non-existent PID is handled gracefully (`kill ... 2>/dev/null`, `wait ... 2>/dev/null || true`).

### 4. Step Counter (`_STEP_CURRENT` / `_STEP_TOTAL`)

**Type**: Global shell variables (integers)
**Set in**: `run.sh` (total set once; current incremented per step)
**Consumed by**: `run_step()` for progress display in pipe mode

| Variable | Purpose |
|----------|---------|
| `_STEP_TOTAL` | Total number of steps (4) |
| `_STEP_CURRENT` | Current step number (1-indexed, incremented by `run_step()`) |

**Used for pipe-mode degraded output**: `"Step 1/4: Detecting server region...done"`

### 5. Error Message (Silent Mode)

**Type**: Fixed strings (no dynamic content from child scripts)
**Defined in**: `00_common.sh` → `_silent_error()` and `run_step()` error path

| Error Context | Generic Message |
|---------------|-----------------|
| Step failure inside `run_step()` | `"❌ Setup failed — please check your configuration"` |
| Validation failure in `run.sh` (missing env var) | `"❌ Setup failed — missing required configuration"` |
| Validation failure in `run.sh` (invalid port) | `"❌ Setup failed — invalid configuration value"` |
| Validation failure in `run.sh` (port conflict) | `"❌ Setup failed — required port is unavailable"` |
| Validation failure in `run.sh` (unsupported OS) | `"❌ Setup failed — unsupported system"` |
| Unexpected/unhandled error (trap) | `"❌ Setup failed — an unexpected error occurred"` |

**Validation rules**:
- Generic error messages MUST NOT contain any banned words (FR-015).
- Generic error messages MUST NOT include dynamic content from child script stderr.
- Exit codes MUST match the real error code from the failing operation (FR-008).

## State Transitions

```
                     run.sh starts
                          │
                          ▼
                  ┌───────────────┐
                  │ Detect mode   │
                  │ (00_common.sh)│
                  └───────┬───────┘
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
         _SILENT_MODE  _SILENT_MODE  _SILENT_MODE
           ="off"     ="interactive"   ="pipe"
              │           │           │
              ▼           ▼           ▼
         [Verbose]   [Spinner +    [Line-based
          Current     Cover Msg]    Progress]
          Behavior        │           │
              │           │           │
              └───────────┼───────────┘
                          │
                    For each step:
                          │
                          ▼
                  ┌───────────────┐
                  │  run_step()   │
                  │  (mode-aware) │
                  └───────┬───────┘
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
           [Success]            [Failure]
           Stop spinner         Stop spinner
           Print ✔              Print generic error
           Next step            Exit with real code
                │
                ▼
         ┌──────────────┐
         │ JSON Payload  │
         │ (always shown)│
         └──────────────┘
```

## Relationships

- `_SILENT_MODE` → determines behavior of `_silent_echo`, `run_step`, `_start_spinner`, `_stop_spinner`, `_silent_error`
- `run_step()` → uses `_SPINNER_PID` (start/stop), `_STEP_CURRENT` (increment), cover message (arg 3)
- `_silent_cleanup()` → uses `_SPINNER_PID` (kill if active), `_SILENT_MODE` (decide whether to print generic error)
- Cover Message Map → consumed by `run_step()` arg 3 → displayed by `_start_spinner()`

