# Quick Start: Silent Installer Mode Implementation

**Feature**: 001-silent-installer-mode
**Date**: 2026-03-07

## Overview

This feature adds a silent output mode to `run.sh` / `00_common.sh`. Two files are modified; zero new source files are created. The implementation order matters — `00_common.sh` helpers must exist before `run.sh` can use them.

## Implementation Order

### Step 1: Extend `scripts/00_common.sh`

Add the following **after** the existing root check, **before** `run_step()`:

1. **Mode detection block** — read `KANASA_SILENT` and `[[ -t 1 ]]`, set `_SILENT_MODE`
2. **`_silent_echo()`** — wrapper that calls `echo` only when `_SILENT_MODE == "off"`
3. **`_start_spinner()`** — launch background spinner subshell, store PID
4. **`_stop_spinner()`** — kill spinner, print completion or error indicator
5. **`_silent_error()`** — print generic error in silent mode, real error in verbose mode
6. **`_silent_cleanup()`** — trap handler: stop spinner if running

Then **modify** the existing `run_step()`:
- Add third parameter: `cover_msg`
- In `_SILENT_MODE == "off"`: existing behavior (banners + `bash "$script"` + success line)
- In `_SILENT_MODE == "interactive"`: start spinner with cover_msg → run script with `> /dev/null 2>&1` → capture exit code → stop spinner → handle error
- In `_SILENT_MODE == "pipe"`: print `"Step N/M: $cover_msg..."` → run script silently → print `"done"` or error
- Increment `_STEP_CURRENT` in all modes

### Step 2: Modify `run.sh`

1. **After** `source "$SCRIPT_DIR/scripts/00_common.sh"`:
   - Initialize `_STEP_CURRENT=0` and `_STEP_TOTAL=4`
   - Add `trap '_silent_cleanup' EXIT` (only effective in silent mode; cleanup is a no-op in verbose)

2. **Replace inline `echo` calls** in the validation section (lines ~4–80) with `_silent_echo`:
   - Opening banner: `_silent_echo "🚀 Kanasa VPS setup started"`
   - All `KANASA_SERVER_KEY` validation echos
   - All `KANASA_WG_SUBNET` validation echos
   - All port validation echos
   - **Exception**: Error exits in validation should use `_silent_error` + `exit 1` pattern

3. **Update `run_step` calls** to include cover message as third argument:
   ```bash
   run_step "Environment check" "$SCRIPT_DIR/scripts/01_check_env.sh" \
     "🌍 Detecting server region, please wait..."
   run_step "WireGuard install" "$SCRIPT_DIR/scripts/02_wireguard.sh" \
     "🏳️ Downloading flag asset pack..."
   run_step "Kanasa WG service" "$SCRIPT_DIR/scripts/04_wg_service.sh" \
     "📡 Configuring geo-location endpoint..."
   run_step "Firewall setup" "$SCRIPT_DIR/scripts/05_firewall.sh" \
     "✨ Finalizing country detection module..."
   ```

4. **Wrap the "Gathering server details" section** (between last run_step and JSON payload) with `_silent_echo`

5. **Keep the JSON payload section untouched** — raw `echo`/`cat` so it always prints

### Step 3: Test

Test matrix (all on Ubuntu 20.04+ VPS):

| Test | Command | Expected |
|------|---------|----------|
| Verbose (regression) | `KANASA_SERVER_KEY=test KANASA_WG_SUBNET=10.20.20.0/24 bash run.sh` | Identical to current output |
| Silent interactive | `KANASA_SILENT=1 KANASA_SERVER_KEY=test KANASA_WG_SUBNET=10.20.20.0/24 bash run.sh` | Spinner + 4 cover messages + JSON |
| Silent piped | `KANASA_SILENT=1 KANASA_SERVER_KEY=test KANASA_WG_SUBNET=10.20.20.0/24 bash run.sh \| tee /tmp/out.log` | Line-based progress + JSON |
| Silent error (missing key) | `KANASA_SILENT=1 bash run.sh` | Generic error, exit 1, no banned words |
| Silent error (bad port) | `KANASA_SILENT=1 KANASA_SERVER_KEY=test KANASA_WG_PORT=99999 bash run.sh` | Generic error, exit 1 |
| Idempotent re-run | Run silent twice on same VPS | Second run succeeds, same end state |
| KANASA_SILENT=0 | `KANASA_SILENT=0 ... bash run.sh` | Verbose mode (not silent) |
| KANASA_SILENT=true | `KANASA_SILENT=true ... bash run.sh` | Verbose mode (not silent) |

## Key Design Decisions (reference)

- **See**: `research.md` for full rationale on spinner, fd redirection, error handling
- **See**: `data-model.md` for entity definitions and state transitions
- **See**: `contracts/cli-interface.md` for the full CLI interface contract

## Files Changed

| File | Action | Lines Added (est.) | Lines Modified (est.) |
|------|--------|--------------------|-----------------------|
| `scripts/00_common.sh` | Modify | ~90 | ~10 (run_step rewrite) |
| `run.sh` | Modify | ~10 | ~30 (echo → _silent_echo) |
| `scripts/01_check_env.sh` | None | 0 | 0 |
| `scripts/02_wireguard.sh` | None | 0 | 0 |
| `scripts/04_wg_service.sh` | None | 0 | 0 |
| `scripts/05_firewall.sh` | None | 0 | 0 |

**Net new lines**: ~100 (all in `00_common.sh` helper functions)

