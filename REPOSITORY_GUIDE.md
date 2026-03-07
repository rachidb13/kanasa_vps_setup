# 📦 Kanasa VPS Setup - Repository Guide

## 🌐 GitHub Repository
**URL**: https://github.com/rachidb13/kanasa_vps_setup  
**Branch**: `001-silent-installer-mode`

---

## 🎯 Overview

This repository provides **two installation modes** for the Kanasa VPS setup:

1. **Verbose Mode** (`run.sh`) - Full detailed output with all installation logs
2. **Silent Mode** (`run-silent.sh`) - Minimal output with fake "country flag" cover messages

---

## 🚀 Quick Installation Commands

### Verbose Mode (Debug & First-Time Setup)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

### Silent Mode (Production & Discreet Deployment)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

---

## 📁 Repository Structure

```
kanasa_vps_setup/
│
├── run.sh                    # Verbose installer entry point
├── run-silent.sh             # Silent installer entry point
│
├── scripts/                  # Verbose mode installation scripts
│   ├── 00_common.sh          # Common utilities for verbose mode
│   ├── 01_check_env.sh       # Environment validation (verbose)
│   ├── 02_wireguard.sh       # WireGuard installation (verbose)
│   ├── 04_wg_service.sh      # Kanasa WG service setup (verbose)
│   ├── 05_firewall.sh        # Firewall configuration (verbose)
│   └── kanasa-wg.service.tpl # Systemd service template
│
├── scripts-silent/           # Silent mode installation scripts
│   ├── 00_common_silent.sh   # Silent mode utilities with spinner
│   ├── 01_check_env_silent.sh       # Environment validation (silent)
│   ├── 02_wireguard_silent.sh       # WireGuard installation (silent)
│   ├── 04_wg_service_silent.sh      # Kanasa WG service setup (silent)
│   ├── 05_firewall_silent.sh        # Firewall configuration (silent)
│   └── kanasa-wg.service.tpl        # Systemd service template
│
├── specs/                    # Feature specifications
│   └── 001-silent-installer-mode/
│       ├── spec.md
│       ├── plan.md
│       ├── quickstart.md
│       ├── data-model.md
│       ├── research.md
│       └── checklists/
│           └── requirements.md
│
└── Documentation Files
    ├── README.md             # Main readme
    ├── QUICKSTART.md         # Quick start guide
    ├── FINAL_COMMANDS.md     # Final commands reference
    ├── IMPLEMENTATION_SUMMARY.md
    ├── COMPLETE.md
    ├── VISUAL_COMPARISON.md
    └── REPOSITORY_GUIDE.md   # This file
```

---

## 🔑 Key Differences Between Modes

### Verbose Mode (`run.sh`)
- **Purpose**: Debugging, troubleshooting, first-time setup
- **Output**: Full logs with all echo statements
- **Messages**: Real infrastructure terms (WireGuard, firewall, etc.)
- **Scripts**: Uses `scripts/` directory
- **Output Volume**: ~60-80 lines

### Silent Mode (`run-silent.sh`)
- **Purpose**: Production deployment, discreet installation
- **Output**: Minimal output with progress spinner
- **Messages**: Fake "country flag module" cover story
- **Scripts**: Uses `scripts-silent/` directory
- **Output Volume**: ~12-15 lines

---

## 📝 Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `KANASA_SERVER_KEY` | ✅ Yes | - | Unique server identifier (e.g., `usa-st-louis`) |
| `KANASA_WG_PORT` | ⚠️ Recommended | `9000` | Port for WireGuard service |
| `KANASA_WG_SUBNET` | ✅ Yes (new install) | - | VPN subnet (e.g., `10.40.46.0/24`) |

---

## 🎭 Silent Mode Cover Story

The silent mode disguises the VPN installation as a **"Country Flag Module"** installation:

**Fake Messages Displayed:**
- 🌍 Detecting server region...
- 🏳️ Downloading flag asset pack...
- 📡 Configuring geo-location endpoint...
- ✨ Finalizing country detection module...

**Success Message:**
```
✅ Country flag module installed successfully
```

---

## 🛠️ What Gets Installed

Both modes install the same components:

1. **WireGuard VPN**
   - Kernel module and tools
   - Interface `wg0` configuration
   - IPv4 forwarding enabled

2. **Kanasa WG Service**
   - Binary downloaded from GitHub releases
   - Systemd service configured and started
   - Runs on configured port (default: 9000)

3. **Firewall Configuration**
   - UFW disabled (open mode)
   - All ports accessible

4. **Server Registration Payload**
   - JSON output with server details
   - Ready to paste into admin panel

---

## 📋 Installation Steps (Both Modes)

1. Environment validation (OS, permissions)
2. WireGuard installation
3. Kanasa WG service setup
4. Firewall configuration
5. Server registration payload generation

---

## ✅ Expected Output (Silent Mode)

```bash
root@vmi3064417:~# export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash

  ⠋ 🌍 Detecting server region...
  ✔ Done
  ⠋ 🏳️ Downloading flag asset pack...
  ✔ Done
  ⠋ 📡 Configuring geo-location endpoint...
  ✔ Done
  ⠋ ✨ Finalizing country detection module...
  ✔ Done

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

========================================================
```

---

## 🔧 Technical Implementation

### Silent Mode Features

1. **Progress Spinner**
   - Uses Unicode spinner characters (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)
   - Background process monitoring
   - Clean cleanup on exit

2. **Output Suppression**
   - All verbose output redirected to log files
   - Only errors and final payload shown
   - Temporary files cleaned up automatically

3. **Error Handling**
   - Port conflicts detected before installation
   - Graceful failure with helpful messages
   - Spinner stopped on errors

### File Organization

- **Separate Script Directories**: `scripts/` vs `scripts-silent/`
- **Shared Templates**: `kanasa-wg.service.tpl` duplicated for independence
- **Common Functions**: Silent mode has its own `00_common_silent.sh`
- **No Cross-Dependencies**: Each mode is completely independent

---

## 🌍 Example Scenarios

### Scenario 1: US Server (St. Louis)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

### Scenario 2: France Server (Paris)
```bash
export KANASA_SERVER_KEY=france-paris
export KANASA_WG_PORT=8500
export KANASA_WG_SUBNET=10.50.10.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

### Scenario 3: Germany Server (Berlin) - Debug Mode
```bash
export KANASA_SERVER_KEY=germany-berlin
export KANASA_WG_PORT=9100
export KANASA_WG_SUBNET=10.60.20.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

---

## ⚠️ Important Notes

### Port Selection
- Choose a unique port for each VPS
- Default is `9000` but **highly recommended** to customize
- Port conflicts will cause installation to fail immediately

### Subnet Selection
- Each VPS needs a unique `/24` subnet
- Examples: `10.40.46.0/24`, `10.50.10.0/24`, `10.60.20.0/24`
- Do not reuse subnets across different VPS instances

### Server Key Naming
- Use descriptive, unique identifiers
- Format: `country-city` (e.g., `usa-st-louis`, `france-paris`)
- This key will be used in the admin panel

---

## 🔍 Troubleshooting

### Port Already in Use
```
❌ Setup failed — required port is unavailable
```
**Solution**: Choose a different port and re-run

### Missing Required Variable
```
❌ Setup failed — missing required configuration
```
**Solution**: Export all required environment variables

### WireGuard Already Installed
- The installer will detect existing configurations
- `KANASA_WG_SUBNET` is only required for new installations
- Existing installations will reuse the current subnet

---

## 📚 Additional Documentation

- **QUICKSTART.md**: Detailed quick start guide
- **FINAL_COMMANDS.md**: Complete command reference
- **IMPLEMENTATION_SUMMARY.md**: Technical implementation details
- **specs/001-silent-installer-mode/**: Feature specifications and planning

---

## 🔗 Raw File URLs

### Installers
- **Verbose**: https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh
- **Silent**: https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh

### Archive
- **Tarball**: https://github.com/rachidb13/kanasa_vps_setup/archive/refs/heads/001-silent-installer-mode.tar.gz

---

## ✨ Summary

This repository provides a **dual-mode installer** for Kanasa VPS setup:

- **Same functionality**, different presentation
- **Independent script directories** for clean separation
- **Production-ready** with proper error handling
- **Discreet silent mode** with cover story
- **Verbose mode** for debugging and troubleshooting

Choose the mode that fits your deployment scenario!

---

**Repository**: https://github.com/rachidb13/kanasa_vps_setup  
**Branch**: `001-silent-installer-mode`  
**Maintainer**: @rachidb13

