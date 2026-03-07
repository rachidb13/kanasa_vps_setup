# 🚀 Kanasa VPS Setup - Quick Start Guide

## Repository
**GitHub**: https://github.com/rachidb13/kanasa_vps_setup

---

## Installation Commands

### Option 1: Verbose Mode (Detailed Output)
Use this for **debugging** and **first-time setup**.

```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

**What you'll see:**
- Full WireGuard installation logs
- Detailed step-by-step output
- All echo statements and diagnostics
- Real infrastructure terms (WireGuard, firewall, etc.)

---

### Option 2: Silent Mode (Minimal Output)
Use this for **production** and **clean deployment**.

```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

**What you'll see:**
- Progress spinner with fake "country flag" messages
- Minimal output (~12 lines vs ~60 lines)
- No VPN/WireGuard terminology
- Clean, discreet installation

**Cover messages shown:**
- ⠋ 🌍 Detecting server region...
- ⠋ 🏳️ Downloading flag asset pack...
- ⠋ 📡 Configuring geo-location endpoint...
- ⠋ ✨ Finalizing country detection module...

---

## Required Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `KANASA_SERVER_KEY` | ✅ Yes | - | Unique server identifier (e.g., usa-st-louis) |
| `KANASA_WG_PORT` | ⚠️ Recommended | 9000 | Port for WireGuard service |
| `KANASA_WG_SUBNET` | ✅ Yes (new install) | - | Subnet for VPN (e.g., 10.40.46.0/24) |

---

## Examples

### Basic Setup (US Server in St. Louis)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

### Basic Setup (France Server)
```bash
export KANASA_SERVER_KEY=france-paris
export KANASA_WG_PORT=8500
export KANASA_WG_SUBNET=10.50.10.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

### Debug Mode (Verbose)
```bash
export KANASA_SERVER_KEY=test-server
export KANASA_WG_PORT=9000
export KANASA_WG_SUBNET=10.10.10.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

---

## Expected Output

### Verbose Mode Output
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
[full installation logs...]
✔ WireGuard ready

[...continues with all steps...]

========================================================
       📝 SERVER REGISTRATION PAYLOAD 📝
========================================================
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

### Silent Mode Output
```
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

---

## Troubleshooting

### Port Already in Use
```
❌❌❌ PORT CONFLICT DETECTED ❌❌❌
Port 7932 is already in use on this VPS.

👉 Please choose another port and re-run:
   export KANASA_SERVER_KEY=usa-st-louis
   export KANASA_WG_PORT=<FREE_PORT>
   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

**Solution**: Use a different port number.

### Missing KANASA_SERVER_KEY
```
❌ KANASA_SERVER_KEY is required

👉 Example:
   export KANASA_SERVER_KEY=france-2
   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

**Solution**: Set the server key before running.

### Unsupported OS
```
❌ Unsupported OS or missing WireGuard
Ubuntu 20.04+ recommended
```

**Solution**: Use Ubuntu 20.04 or newer.

---

## After Installation

After successful installation, you'll receive a **JSON payload** to paste into your admin panel:

```json
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

**Copy this entire JSON block and paste it into your Kanasa admin panel to register the server.**

---

## Key Differences

| Feature | Verbose Mode | Silent Mode |
|---------|-------------|-------------|
| **Output Lines** | ~60 lines | ~12 lines |
| **Shows WireGuard** | ✅ Yes | ❌ No |
| **Shows VPN Terms** | ✅ Yes | ❌ No |
| **Cover Story** | ❌ No | ✅ Yes (flag detection) |
| **Best For** | Debugging | Production |
| **Installer URL** | `.../run.sh` | `.../run-silent.sh` |

---

## Support

- **Repository**: https://github.com/rachidb13/kanasa_vps_setup
- **Issues**: https://github.com/rachidb13/kanasa_vps_setup/issues

---

**Last Updated**: March 7, 2026  
**Version**: 2.0 (Dual-file architecture)

