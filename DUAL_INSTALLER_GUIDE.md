# Dual Installer Mode - Implementation Summary

## Overview
The installer has been restructured to have **two completely separate implementations**:

1. **Verbose Mode** (`run.sh` + `scripts/`)
   - Full detailed output with echo statements
   - Shows real installation steps
   - Great for debugging and first-time setups

2. **Silent Mode** (`run-silent.sh` + `scripts-silent/`)
   - Minimal output with progress spinner
   - Fake "country flag installation" messages
   - All actual work (WireGuard, firewall, etc.) runs silently in background

## File Structure

```
kanasa-vps-setup/
├── run.sh                          # Verbose installer entry point
├── run-silent.sh                   # Silent installer entry point
│
├── scripts/                        # Verbose mode scripts
│   ├── 00_common.sh               # Verbose helper functions
│   ├── 01_check_env.sh            # With echo output
│   ├── 02_wireguard.sh            # With echo output
│   ├── 04_wg_service.sh           # With echo output
│   ├── 05_firewall.sh             # With echo output
│   └── kanasa-wg.service.tpl
│
└── scripts-silent/                 # Silent mode scripts
    ├── 00_common_silent.sh        # Silent helper functions
    ├── 01_check_env_silent.sh     # No output (redirected to /dev/null)
    ├── 02_wireguard_silent.sh     # No output (redirected to /dev/null)
    ├── 04_wg_service_silent.sh    # No output (redirected to /dev/null)
    ├── 05_firewall_silent.sh      # No output (redirected to /dev/null)
    └── kanasa-wg.service.tpl
```

## How to Use

### Verbose Installation (Detailed Output)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash
```

**Output Example:**
```
🚀 Kanasa VPS setup started
📦 Fetching Kanasa setup repository...
🔍 Checking availability of port 7932...
✔ Port 7932 is free

==============================
▶ Environment check
==============================
🔍 Checking environment...
OS: Ubuntu 24.04
✔ Ubuntu 24.04 supported
✔ Environment check completed

==============================
▶ WireGuard install
==============================
🔐 WireGuard setup...
📦 Installing WireGuard...
[apt install output...]
✔ WireGuard ready
...
```

### Silent Installation (Minimal Output)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run-silent.sh | bash
```

**Output Example:**
```
  ✔ Done
  ✔ Done
  ⠋ 🏳️ Downloading flag asset pack...
  ✔ Done
  ⠋ 📡 Configuring geo-location endpoint...

✅ Country flag module installed successfully

🔍 Gathering server details...

========================================================
       📝 SERVER REGISTRATION PAYLOAD 📝
========================================================
Copy the JSON block below and paste it into the admin panel:

{
  "server_key": "usa-st-louis",
  "country": "United States",
  "city": "St Louis",
  "endpoint": "212.28.176.250",
  "agent_url": "http://212.28.176.250:7932",
  "public_key": "hd2qEm4Zta87IikfsRn69vl41+2BvyAW4NcaBWgiTAs=",
  "listen_port": 7932
}
```

## Key Differences

### Verbose Mode (`run.sh`)
- **Purpose**: Debugging, development, first-time setup
- **Output**: Full details of every command
- **Messages**: Real WireGuard/firewall installation messages
- **Scripts**: Original scripts with all echo statements intact
- **Common Functions**: Simple `run_step()` that shows section headers

### Silent Mode (`run-silent.sh`)
- **Purpose**: Production deployments, clean UI
- **Output**: Only spinner + fake messages + final JSON payload
- **Messages**: Fake "country flag" installation messages to disguise VPN setup
- **Scripts**: Modified to redirect all output to `/dev/null 2>&1`
- **Common Functions**: Advanced `run_step()` with spinner support

## Cover Messages in Silent Mode

The silent installer shows these fake messages while actually installing WireGuard:

1. 🌍 Detecting server region...
2. 🏳️ Downloading flag asset pack...
3. 📡 Configuring geo-location endpoint...
4. ✨ Finalizing country detection module...

## Benefits of This Approach

✅ **Clean Separation**: No conditional logic mixing in the same files
✅ **Maintainability**: Each mode is independent and easy to understand
✅ **No Conflicts**: Changes to one mode don't affect the other
✅ **Performance**: Silent mode doesn't check `KANASA_SILENT` repeatedly
✅ **Flexibility**: Can customize each mode differently without constraints

## Migration Notes

- Old command with `KANASA_SILENT=1` variable is now obsolete
- Use `run-silent.sh` instead of `run.sh` for silent mode
- Both installers produce the same end result (JSON payload)
- Both installers use the same validation logic

