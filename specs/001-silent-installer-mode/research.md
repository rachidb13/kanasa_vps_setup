# Research: Silent Installer Mode

**Feature**: 001-silent-installer-mode
**Date**: 2026-03-07
**Status**: Complete

## Research Tasks

### R1: Spinner Implementation in Pure Bash

**Context**: FR-005 requires a progress spinner alongside cover messages. Must work in bash 4.0+ with zero external dependencies on Ubuntu 20.04+.

**Decision**: Use a background subshell spinner with `\r` (carriage return) overwriting.

**Rationale**:
- Background subshell approach allows the spinner to animate while the real work runs in the foreground.
- Using `\r` to overwrite the current line keeps output clean — one line per step, not scrolling text.
- Spinner characters `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (braille dots) provide smooth animation on modern terminals. Fallback to `| / - \` for non-UTF-8 terminals.
- `sleep 0.1` between frames gives 10 fps — smooth enough without CPU overhead.
- The spinner PID is stored in a global variable (`_SPINNER_PID`) so it can be killed from `_stop_spinner()` or the cleanup trap.

**Alternatives considered**:
1. **`pv` (pipe viewer)**: External dependency, not installed by default on Ubuntu. Rejected per constraint "zero external deps."
2. **`dialog` / `whiptail`**: TUI libraries that need a full terminal. Don't work over `curl | bash` without a TTY. Rejected.
3. **Inline printf loop in foreground**: Would block the real work from running. Rejected because we need concurrent execution.
4. **`tput` cursor manipulation**: Works but adds complexity (save/restore cursor position). `\r` is simpler and sufficient for a single-line spinner.

**Implementation pattern**:
```bash
_start_spinner() {
  local msg="$1"
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  (
    local i=0
    while true; do
      printf "\r  %s %s " "${frames[$((i % ${#frames[@]}))]}" "$msg"
      sleep 0.1
      ((i++))
    done
  ) &
  _SPINNER_PID=$!
}

_stop_spinner() {
  local success="${1:-true}"
  if [[ -n "${_SPINNER_PID:-}" ]]; then
    kill "$_SPINNER_PID" 2>/dev/null
    wait "$_SPINNER_PID" 2>/dev/null || true
    _SPINNER_PID=""
  fi
  if [[ "$success" == "true" ]]; then
    printf "\r  ✔ Done                              \n"
  fi
}
```

### R2: File Descriptor Redirection Strategy

**Context**: In silent mode, `run_step()` calls child scripts whose stdout/stderr must be suppressed. Additionally, `run.sh` has ~80 lines of inline `echo` statements (port validation, subnet checks, "Gathering server details...") that must also be suppressed. The final JSON payload must ALWAYS be shown.

**Decision**: Dual-layer redirection approach:
1. **Layer 1 — `run_step()` wrapper**: In silent mode, run child scripts with `> /dev/null 2>&1` to suppress all their output.
2. **Layer 2 — `_silent_echo` helper**: Replace all inline `echo` calls in `run.sh` with `_silent_echo` which is a no-op in silent mode and a passthrough `echo` in verbose mode.
3. **Layer 3 — always-print helper**: The final JSON payload section uses raw `echo`/`cat` directly (not `_silent_echo`) so it always prints regardless of mode.

**Rationale**:
- Layer 1 is clean: `run_step()` already wraps child script execution, so adding redirection is a one-line change.
- Layer 2 avoids the need for global fd redirection (which would be fragile and hard to selectively undo for the JSON payload).
- Layer 3 is explicit: the "always show" sections simply don't use the wrapper function.
- This approach requires editing `run.sh` to replace `echo` with `_silent_echo` in the validation sections, but this is a mechanical find-and-replace that doesn't change logic.

**Alternatives considered**:
1. **Global `exec > /dev/null` with fd save/restore**: Redirect all of stdout at script start, save fd 3 for "always print." Rejected because it's fragile — any missed `>&3` would silently lose output, and it makes the script much harder to debug.
2. **Subshell wrapper around entire run.sh**: Run the whole script in a subshell with redirected output. Rejected because `set -e` and `trap` don't propagate cleanly across subshell boundaries, and exit codes become unreliable.
3. **Separate silent entry-point script**: Create a `run-silent.sh` that sources `run.sh`. Rejected because it duplicates the entry point and violates the "single entry point" principle.

### R3: Error Handling in Silent Mode

**Context**: FR-007 requires that errors use generic language. FR-012 requires that the spinner stops on failure. The installer uses `set -e` so errors cause immediate exit.

**Decision**: Three-pronged error handling:
1. **`run_step()` exit code capture**: Disable `set -e` locally around the child script call, capture the exit code, then re-check. If non-zero: stop spinner, print generic error, exit with the captured code.
2. **Trap handler in `run.sh`**: A top-level `trap '_silent_cleanup' EXIT` that stops any running spinner and, if exit code is non-zero, prints a generic error message.
3. **`_silent_error` function**: A helper that prints a generic error in silent mode or the real error in verbose mode.

**Rationale**:
- Capturing exit codes inside `run_step()` gives us step-level granularity — we know which step failed and can stop that step's spinner.
- The trap handler is a safety net for errors that occur outside of `run_step()` (e.g., in the inline validation section of `run.sh`).
- Generic error messages (e.g., "❌ Setup failed — please check your configuration") satisfy FR-007 and FR-015.

**Implementation pattern**:
```bash
# Inside run_step() in silent mode:
set +e
bash "$script" > /dev/null 2>&1
local rc=$?
set -e

if [[ $rc -ne 0 ]]; then
  _stop_spinner false
  _silent_error "Setup failed at step $step_num — please check your configuration"
  exit $rc
fi
```

**Alternatives considered**:
1. **Let `set -e` propagate naturally**: Rely on bash's native error handling. Rejected because we'd lose the chance to stop the spinner and print a generic message — the script would just terminate with the real error text from the child script (which is suppressed, so the user sees nothing).
2. **`trap ERR` instead of exit code capture**: Rejected because `ERR` traps don't fire in subshells or piped commands reliably in bash 4.0.
3. **Per-script error wrapping**: Add try/catch-like wrappers in each step script. Rejected because FR-013 says individual scripts need NO modification.

### R4: Non-Interactive Terminal Graceful Degradation

**Context**: Edge case from spec — what if stdout is piped to a file or a non-interactive terminal? Spinner escape codes would corrupt the output.

**Decision**: Detect interactivity with `[[ -t 1 ]]` (test if fd 1 is a terminal). If non-interactive in silent mode, degrade to simple line-based output without `\r` or spinner characters.

**Rationale**:
- `[[ -t 1 ]]` is a POSIX-compatible test that's reliable in bash 4.0+.
- Degraded output format: `"Step 1/4: Checking environment...done"` — informative without escape codes.
- This matches the edge case specification exactly.

**Implementation pattern**:
```bash
if [[ "${KANASA_SILENT:-}" == "1" ]] && [[ -t 1 ]]; then
  _SILENT_MODE="interactive"  # spinner + cover messages
elif [[ "${KANASA_SILENT:-}" == "1" ]]; then
  _SILENT_MODE="pipe"         # line-based cover messages, no spinner
else
  _SILENT_MODE="off"          # verbose (current behavior)
fi
```

### R5: Inline Echo Replacement Strategy in run.sh

**Context**: `run.sh` has ~50 inline `echo` statements for validation messages, banners, and diagnostics. These must be suppressed in silent mode but are NOT inside `run_step()` calls.

**Decision**: Introduce `_silent_echo` function and mechanically replace all inline `echo` calls in `run.sh` (except the final JSON payload section) with `_silent_echo`.

**Rationale**:
- `_silent_echo` is a simple wrapper: in verbose mode it calls `echo "$@"`, in silent mode it's a no-op (returns 0).
- This is the minimum-diff approach — every line changes only the command name (`echo` → `_silent_echo`), preserving all arguments and formatting.
- The final JSON section (lines ~140–163 in current `run.sh`) keeps raw `echo`/`cat` calls because FR-006 says the payload must always be shown.
- The "Gathering server details..." section between the last `run_step` and the JSON payload also uses `_silent_echo` since it's diagnostic output.

**Alternatives considered**:
1. **Redirect all of stdout for the validation section**: Use `{ ... } > /dev/null` around the validation block. Rejected because the block spans non-contiguous sections of `run.sh` and would require major restructuring.
2. **Move all validation into a step script**: Create `00_validate.sh`. Rejected because validation in `run.sh` has access to variables set inline (port, subnet) and restructuring would change the control flow.

### R6: Cover Message Map Design

**Context**: FR-014 defines a 1:1 mapping of real steps to cover messages. This map needs to be defined centrally.

**Decision**: Pass the cover message as a third argument to `run_step()`.

**Rationale**:
- Keeps the mapping visible and centralized in `run.sh` right next to the `run_step` calls.
- No separate config file or associative array needed — the mapping is implicit in the call site.
- In verbose mode, the third argument is simply ignored.

**Implementation**:
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

**Alternatives considered**:
1. **Associative array in `00_common.sh`**: `declare -A COVER_MESSAGES`. Rejected because it separates the mapping from the call site, making it harder to see which step gets which message.
2. **Separate config file**: `cover-messages.conf`. Rejected as over-engineering for 4 entries and adds a file dependency.

