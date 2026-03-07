# Feature Specification: Silent Installer Mode

**Feature Branch**: `001-silent-installer-mode`  
**Created**: 2026-03-07  
**Status**: Implemented  
**Architecture**: Dual-file separation (verbose and silent modes use separate script sets)

**Input**: User description: "I want to have 2 installers: this one I have, full of reporting on each step with echo, and another one totally silent that has only a progress bar or loading design while I'm waiting, saying 'getting the country flag for current VPS please wait', and if I want to run the silent one I just change something in the installer command. The silent messages should NOT reveal what is actually being installed — they should look like we're installing a country-flag detection script for the Android app."

## Architecture Decision

Instead of using a single set of scripts with conditional `KANASA_SILENT` environment variable switching, this implementation uses **completely separate files** for each mode:

- **Verbose Mode**: `run.sh` + `scripts/` (original files, unchanged)
- **Silent Mode**: `run-silent.sh` + `scripts-silent/` (new silent-only files)

### Benefits of This Approach

1. **Clean Separation**: No conditional logic mixing in the same files
2. **Maintainability**: Each mode is independent and easy to understand  
3. **No Conflicts**: Changes to one mode don't affect the other
4. **Performance**: Silent mode doesn't check variables repeatedly
5. **Flexibility**: Can customize each mode differently without constraints

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run Installer in Silent Mode (Priority: P1)

As a VPS operator, I want to run the silent installer by using `run-silent.sh` instead of `run.sh` so that the terminal displays only a cover story — progress messages that look like a simple "country flag detection" utility is being installed for the Android app — while all real infrastructure (WireGuard, services, firewall) is installed silently in the background.

**Why this priority**: This is the core value of the feature — providing a discreet installation experience where the on-screen output reveals nothing about the actual infrastructure being provisioned. Without this, the feature has no reason to exist.

**Independent Test**: Can be fully tested by running `run-silent.sh` on a fresh Ubuntu VPS and observing that (a) no real step names or technical details appear on screen, (b) only country-flag-themed cover messages are shown with a progress indicator, and (c) the final JSON registration payload is shown at the end.

**Acceptance Scenarios**:

1. **Given** a fresh Ubuntu VPS with no prior installation, **When** the user runs `run-silent.sh`, **Then** no real per-step echo output (WireGuard, systemd, firewall, banners, emoji status lines, diagnostics) is displayed at any point.
2. **Given** a fresh Ubuntu VPS using `run-silent.sh`, **When** each installation step is executing, **Then** a progress indicator (spinner/animation) is displayed with a fake cover message themed around country-flag detection (e.g., "🌍 Detecting server region...", "🏳️ Downloading flag asset pack...", "📡 Configuring geo-location endpoint...").
3. **Given** a fresh Ubuntu VPS using `run-silent.sh`, **When** all installation steps complete successfully, **Then** the final server registration payload JSON block is displayed exactly as it would be in verbose mode.
4. **Given** a fresh Ubuntu VPS using `run-silent.sh`, **When** the installer finishes, **Then** the exit code is 0 (success), identical to verbose mode behavior.
5. **Given** a fresh Ubuntu VPS using `run-silent.sh`, **When** a bystander reads the terminal output, **Then** all visible messages suggest only a country-flag utility is being installed — no mention of WireGuard, VPN, tunnels, keys, firewall, or systemd services appears.

---

### User Story 2 - Run Installer in Verbose Mode (Priority: P1)

As a VPS operator, I want the default installer behavior (`run.sh`) to remain completely unchanged so that my existing workflow and troubleshooting process is not disrupted.

**Why this priority**: Equal to P1 because breaking the existing verbose installer would be a regression. This is a non-negotiable backward compatibility requirement.

**Independent Test**: Can be fully tested by running `run.sh` on a fresh Ubuntu VPS and observing that all current echo output, banners, emoji-prefixed status lines, and diagnostics appear exactly as they do today.

**Acceptance Scenarios**:

1. **Given** a fresh Ubuntu VPS using `run.sh`, **When** the user runs the installer, **Then** all existing echo output, step banners, emoji-prefixed status lines, and diagnostics are displayed exactly as before.
2. **Given** a fresh Ubuntu VPS using `run.sh`, **When** the installer finishes, **Then** the exit code and final registration payload are identical to the current behavior.

---

### User Story 3 - Errors Surface in Silent Mode Without Revealing Real Infrastructure (Priority: P1)

As a VPS operator running the silent installer, I want critical errors to break through the silent mode so that I am immediately aware of failures, but error messages MUST be kept generic (e.g., "Setup failed — please check your configuration") rather than exposing WireGuard, VPN, or firewall details.

**Why this priority**: Equal to P1 because silent mode that hides errors would create a dangerous operational blind spot. Errors must always be visible regardless of mode, but they must stay consistent with the cover story.

**Independent Test**: Can be fully tested by running `run-silent.sh` on a VPS with a deliberately broken configuration (e.g., unsupported OS, missing `KANASA_SERVER_KEY`, port conflict) and observing that a generic error message is displayed and the installer exits with a non-zero exit code — without mentioning WireGuard, VPN, tunnels, or firewall in the visible output.

**Acceptance Scenarios**:

1. **Given** `run-silent.sh` is used and `KANASA_SERVER_KEY` is not set, **When** the installer runs, **Then** a generic error message (e.g., "❌ Setup failed — missing required configuration") is displayed and the installer exits with a non-zero code. The error does NOT mention WireGuard or VPN.
2. **Given** `run-silent.sh` is used and the VPS runs an unsupported OS, **When** the environment check step executes, **Then** a generic error message (e.g., "❌ Setup failed — unsupported system") is displayed and the installer exits with a non-zero code.
3. **Given** `run-silent.sh` is used and a port is already in use, **When** the port check executes, **Then** a generic error message (e.g., "❌ Setup failed — required port is unavailable") is displayed and the installer exits with a non-zero code. The error does NOT mention WireGuard listen ports.
4. **Given** `run-silent.sh` is used and any installation step fails, **When** the failure occurs, **Then** the progress indicator stops, a generic failure message is shown (real stderr is suppressed from the terminal), and the installer exits with the same non-zero exit code as verbose mode.

---

### User Story 4 - Cover Story Messages Are Convincing and Themed (Priority: P2)

As a VPS operator watching the silent installer, I want each step's fake progress message to tell a coherent "country flag detection" story so that the on-screen narrative feels natural and believable to anyone reading the terminal.

**Why this priority**: This is a quality-of-life and operational-security improvement. The installer technically works with any placeholder text, but a convincing themed narrative is what makes the silent mode truly useful.

**Independent Test**: Can be fully tested by running `run-silent.sh` and verifying that each installation step displays a distinct, themed cover message that fits the "installing a country-flag geo-detection utility" narrative.

**Acceptance Scenarios**:

1. **Given** `run-silent.sh` is used, **When** the environment check step runs, **Then** a cover message like "🌍 Detecting server region..." is shown alongside the progress indicator.
2. **Given** `run-silent.sh` is used, **When** the WireGuard installation step runs (the longest step), **Then** a cover message like "🏳️ Downloading flag asset pack..." is shown alongside the progress indicator.
3. **Given** `run-silent.sh` is used, **When** the service setup step runs, **Then** a cover message like "📡 Configuring geo-location endpoint..." is shown alongside the progress indicator.
4. **Given** `run-silent.sh` is used, **When** the firewall step runs, **Then** a cover message like "✨ Finalizing country detection module..." is shown alongside the progress indicator.
5. **Given** `run-silent.sh` is used, **When** a step completes successfully, **Then** the progress indicator for that step stops and a brief completion indicator (e.g., a checkmark) is shown before moving to the next step.

---

### User Story 5 - Idempotent Re-runs in Silent Mode (Priority: P2)

As a VPS operator, I want to safely re-run the installer in silent mode on an already-provisioned VPS so that idempotency guarantees are preserved regardless of which installer is used.

**Why this priority**: Idempotency is a core project principle. Silent mode must not alter the installer's decision-making or re-run safety.

**Independent Test**: Can be fully tested by running `run-silent.sh` twice on the same VPS and verifying that the second run completes successfully without duplicating configuration or breaking existing services.

**Acceptance Scenarios**:

1. **Given** a VPS that was previously provisioned with `run.sh`, **When** the user re-runs using `run-silent.sh`, **Then** the installer completes successfully, preserving existing configuration and services.
2. **Given** a VPS that was previously provisioned with `run-silent.sh`, **When** the user re-runs using `run-silent.sh`, **Then** the installer completes successfully, identical to re-running in verbose mode.

---

### Edge Cases

- What happens when a user accidentally runs `run-silent.sh` when they wanted verbose output? They must simply re-run with `run.sh` to see detailed output. Both installers are idempotent, so no harm is done.
- What happens when the terminal does not support ANSI escape codes (e.g., piped to a file or non-interactive terminal)? The progress indicator degrades gracefully to simple line-based output (e.g., "Step 1/4: Checking environment...done").
- What happens when the installer is run via `curl | bash` (non-interactive, piped input)? The progress indicator works correctly since the output stream (stdout) is still attached to a terminal.
- What happens when a step takes an unusually long time (e.g., slow network during binary download)? The progress indicator continues to animate without timing out, matching the same timeout behavior as verbose mode.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The installer MUST support two output modes: verbose (`run.sh`) and silent (`run-silent.sh`), implemented as separate file sets.
- **FR-002**: Silent mode MUST be activated by using `run-silent.sh` instead of `run.sh` in the curl command.
- **FR-003**: The verbose installer (`run.sh` + `scripts/`) MUST behave identically to the original implementation with no changes to existing output.
- **FR-004**: In silent mode, all per-step echo output (banners, emoji-prefixed status lines, step diagnostics) MUST be suppressed — no real installation details (WireGuard, VPN, tunnels, keys, firewall, systemd) may appear on screen.
- **FR-005**: In silent mode, each installation step MUST display a progress indicator (spinner or loading animation) accompanied by a **fake cover message** themed around "country-flag detection for the Android app." The cover messages MUST NOT reveal the real infrastructure being installed.
- **FR-006**: In silent mode, upon successful completion, the installer MUST display the final server registration payload JSON block.
- **FR-007**: In silent mode, error messages MUST still cause the installer to exit with the correct non-zero code, but visible error text MUST use generic language (e.g., "Setup failed") rather than exposing real infrastructure names like WireGuard or firewall.
- **FR-008**: In silent mode, the installer MUST preserve the same exit codes as verbose mode (0 for success, non-zero for failures).
- **FR-009**: The silent mode scripts (`scripts-silent/`) MUST redirect all output to `/dev/null 2>&1` to suppress detailed logs.
- **FR-010**: Silent mode MUST NOT alter any installation logic, configuration outcomes, or idempotency guarantees.
- **FR-011**: Silent mode MUST NOT change the security posture of the installer (no additional ports opened, no credentials logged, no permissions altered).
- **FR-012**: The progress indicator MUST stop and be replaced by a generic error message when a step fails.
- **FR-013**: The `run_step()` function in `scripts-silent/00_common_silent.sh` MUST handle output redirection, so individual step scripts can focus solely on their installation logic.
- **FR-014**: The cover message sequence MUST map one-to-one to the real installation steps, presenting a coherent narrative. The predefined mapping MUST be:
  - Environment check → "🌍 Detecting server region..."
  - WireGuard install → "🏳️ Downloading flag asset pack..."
  - Kanasa WG service → "📡 Configuring geo-location endpoint..."
  - Firewall setup → "✨ Finalizing country detection module..."
- **FR-015**: No cover message may contain any of the following words or their variants: WireGuard, VPN, tunnel, firewall, iptables, systemd, wg0, sysctl, UFW, private key, public key.
- **FR-016**: The verbose mode scripts (`scripts/`) MUST remain completely unchanged from their original implementation to maintain backward compatibility.

### Key Entities

- **Output Mode**: Determined by which installer file is used: `run.sh` for verbose, `run-silent.sh` for silent.
- **Progress Indicator**: A visual element (spinner/animation + cover message text) shown in silent mode during each installation step to communicate that work is in progress.
- **Cover Message**: A fake, country-flag-themed label for each installation step (e.g., "🌍 Detecting server region...", "🏳️ Downloading flag asset pack...") displayed alongside the progress indicator in silent mode. These messages deliberately conceal the real nature of the step being executed and present a coherent narrative about installing a country-flag detection utility for an Android app.
- **Cover Story Mapping**: A one-to-one map of real installation steps to their corresponding fake cover messages, defined centrally in `run-silent.sh`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can switch between verbose and silent mode by changing the script name in their curl command (`run.sh` vs `run-silent.sh`) — no environment variables, no additional downloads required.
- **SC-002**: In silent mode, the total number of output lines during a successful installation is reduced by at least 80% compared to verbose mode (excluding the final JSON payload).
- **SC-003**: In silent mode, every installation step displays a visible progress indicator so the user never sees a frozen, output-free terminal for more than 1 second during active work.
- **SC-004**: All error conditions that cause the verbose installer to exit with a non-zero code also cause the silent installer to exit with the same non-zero code and display the error message.
- **SC-005**: Running `run-silent.sh` on an already-provisioned VPS produces the same end state (services running, configuration intact) as running `run.sh` — 100% behavioral parity excluding output formatting.
- **SC-006**: The verbose mode scripts (`scripts/`) remain completely unmodified, ensuring zero regression for existing users.

## Assumptions

- The dual-file architecture is preferred over environment variable switching for better code separation and maintainability.
- The progress indicator will use terminal-compatible spinner characters (e.g., `⠋`, `⠙`, `⠹`, `⠸`) that work in standard Linux terminal emulators. ANSI color codes may be used if the terminal supports them, with graceful degradation.
- The fake cover messages (e.g., "🌍 Detecting server region...", "🏳️ Downloading flag asset pack...") will be defined in `run-silent.sh` alongside each `run_step()` call, keeping the mapping of steps to cover messages centralized.
- The cover story narrative follows a logical progression: detect region → download flag assets → configure endpoint → finalize module. This order matches the real step execution order, making the narrative feel natural.
- The `run_step()` function in `scripts-silent/00_common_silent.sh` will handle stdout/stderr redirection internally by passing logs to temporary files.
- The existing `curl | bash` delivery mechanism is fully compatible with silent mode since stdout remains attached to the user's terminal.
- Performance expectations are standard: no additional latency is introduced by silent mode; the progress indicator is lightweight.
- The final JSON payload block shown at the end in silent mode is acceptable to display as-is (it contains `server_key`, `country`, `public_key`, etc.) since the operator needs this data. This is the only place where real field names appear.









