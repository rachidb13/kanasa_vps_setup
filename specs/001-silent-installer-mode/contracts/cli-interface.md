# CLI Interface Contract: Silent Installer Mode

**Feature**: 001-silent-installer-mode
**Date**: 2026-03-07

## Environment Variables

### New Variable

| Variable | Required | Default | Valid Values | Description |
|----------|----------|---------|--------------|-------------|
| `KANASA_SILENT` | No | unset | `1` (all other values treated as unset) | Activates silent output mode when set to `1` |

### Existing Variables (unchanged)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `KANASA_SERVER_KEY` | Yes | — | Server identifier (e.g., `france-2`) |
| `KANASA_WG_PORT` | No | `9000` | WireGuard listen port (1–65535) |
| `KANASA_WG_SUBNET` | Conditional | — | Required for new installs only (e.g., `10.20.20.0/24`) |

## Invocation

### Verbose Mode (default, unchanged)

```bash
export KANASA_SERVER_KEY=france-2
export KANASA_WG_SUBNET=10.20.20.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash
```

### Silent Mode (new)

```bash
export KANASA_SERVER_KEY=france-2
export KANASA_WG_SUBNET=10.20.20.0/24
export KANASA_SILENT=1
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash
```

## Exit Codes

| Code | Meaning | Changed? |
|------|---------|----------|
| `0` | Success — all steps completed | No |
| `1` | Failure — missing config, unsupported OS, step failure, port conflict | No |

**Contract**: Exit codes are identical in both modes. Silent mode MUST NOT alter exit code semantics.

## Stdout Contract

### Verbose Mode (unchanged)

Full output including:
- Step banners (`======== ▶ Step Name ========`)
- Emoji-prefixed status lines (`✔`, `❌`, `🔍`, `⚙️`)
- Validation diagnostics (port check, subnet check)
- Final JSON registration payload

### Silent Mode — Interactive Terminal

When `KANASA_SILENT=1` and stdout is a terminal:

```
  ⠋ 🌍 Detecting server region, please wait...
```
↓ (spinner animates, then on completion)
```
  ✔ Done
  ⠋ 🏳️ Downloading flag asset pack...
```
↓ (continues for each step, then)
```
  ✔ Done

========================================================
       📝 SERVER REGISTRATION PAYLOAD 📝
========================================================
Copy the JSON block below and paste it into the admin panel:

{
  "server_key": "france-2",
  "country": "France",
  "city": "Paris",
  ...
}

========================================================
```

### Silent Mode — Piped/Non-Interactive

When `KANASA_SILENT=1` and stdout is NOT a terminal:

```
Step 1/4: Detecting server region...done
Step 2/4: Downloading flag assets...done
Step 3/4: Configuring geo-location...done
Step 4/4: Finalizing detection module...done

========================================================
       📝 SERVER REGISTRATION PAYLOAD 📝
========================================================
...
```

### Error Output (Silent Mode)

On failure, spinner stops and a generic error is shown:

```
  ❌ Setup failed — please check your configuration
```

The error message:
- MUST NOT contain: WireGuard, VPN, tunnel, firewall, iptables, systemd, wg0, sysctl, UFW, private key, public key
- MUST be followed by exit with the real non-zero exit code

## Backward Compatibility

| Aspect | Guarantee |
|--------|-----------|
| Default behavior (no `KANASA_SILENT`) | Byte-for-byte identical stdout, identical exit codes |
| `curl \| bash` delivery | Fully compatible (stdout attached to terminal) |
| Existing env vars | No changes to names, semantics, or defaults |
| Script file interface | `run.sh` remains sole entry point; no new scripts |
| Step scripts (01–05) | Zero modifications required |

## Function Interface Changes

### `run_step()` — Enhanced Signature

```
run_step <step_name> <script_path> [cover_message]
```

| Argument | Required | Description |
|----------|----------|-------------|
| `step_name` | Yes | Human-readable step name (used in verbose mode banners) |
| `script_path` | Yes | Path to the step script |
| `cover_message` | Yes (when silent mode is supported) | Fake cover message for silent mode display |

**Backward compatibility**: The third argument is ignored in verbose mode. Existing behavior is preserved when `_SILENT_MODE == "off"`.

