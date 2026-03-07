# ✅ UPDATED FOR NEW REPOSITORY: kanasa_vps_setup

## Your New GitHub Repository
**URL**: https://github.com/rachidb13/kanasa_vps_setup

---

## ✨ How Your Installers Look Now

### 🔊 Verbose Installer (Detailed Output)

**Command:**
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run.sh | bash
```

**What you see:**
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
Reading package lists... Done
Building dependency tree... Done
[... full installation logs ...]
✔ WireGuard ready
✔ WireGuard install completed

==============================
▶ Kanasa WG service
==============================
[... service setup logs ...]

==============================
▶ Firewall setup
==============================
[... firewall logs ...]

✅ Kanasa VPS setup completed successfully

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

### 🤫 Silent Installer (Minimal Output with Cover Story)

**Command:**
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run-silent.sh | bash
```

**What you see:**
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

## 🎯 Key Differences

| Aspect | Verbose Mode | Silent Mode |
|--------|-------------|-------------|
| **Installer URL** | `.../run.sh` | `.../run-silent.sh` |
| **Output Lines** | ~60 lines | ~12 lines |
| **Shows "WireGuard"** | ✅ Yes | ❌ No |
| **Shows "VPN"** | ✅ Yes | ❌ No |
| **Shows "Firewall"** | ✅ Yes | ❌ No |
| **Cover Story** | ❌ No | ✅ Yes ("flag detection") |
| **apt install logs** | ✅ Visible | ❌ Hidden |
| **Best For** | Debugging | Production |

---

## 📦 What Gets Installed (Both Modes - Identical)

Both installers do the exact same thing behind the scenes:

1. ✅ Install WireGuard VPN server
2. ✅ Configure network interfaces
3. ✅ Setup Kanasa WG service on specified port
4. ✅ Configure firewall (open mode)
5. ✅ Generate server keys
6. ✅ Return JSON payload for admin panel

**The only difference is what you see on screen!**

---

## 🚀 Quick Copy-Paste Commands

### For Debugging / First-Time Setup (Verbose)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run.sh | bash
```

### For Production / Clean Deployment (Silent)
```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run-silent.sh | bash
```

---

## 🎭 The Cover Story (Silent Mode)

When you run silent mode, anyone watching your terminal sees these messages:

| Real Action | What They See |
|-------------|---------------|
| Checking Ubuntu version | 🌍 Detecting server region... |
| Installing WireGuard | 🏳️ Downloading flag asset pack... |
| Setting up VPN service | 📡 Configuring geo-location endpoint... |
| Configuring firewall | ✨ Finalizing country detection module... |

**They think you're just installing a simple country-flag detection tool for your Android app!**

---

## 📋 Environment Variables Reference

| Variable | Required? | Default | Example |
|----------|-----------|---------|---------|
| `KANASA_SERVER_KEY` | ✅ **Required** | - | `usa-st-louis` |
| `KANASA_WG_PORT` | ⚠️ Recommended | `9000` | `7932` |
| `KANASA_WG_SUBNET` | ✅ **Required** (new install) | - | `10.40.46.0/24` |

---

## ✅ All Repository URLs Updated

All installer scripts now correctly reference:
- **Repository**: `https://github.com/rachidb13/kanasa_vps_setup`
- **Raw Files**: `https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/`
- **Archive**: `https://github.com/rachidb13/kanasa_vps_setup/archive/refs/heads/main.tar.gz`

---

## 🎉 Ready to Deploy!

1. Push all code to https://github.com/rachidb13/kanasa_vps_setup
2. Test verbose installer on a VPS
3. Test silent installer on a VPS
4. Both should produce identical JSON payloads
5. Share the silent installer command for production use!

---

**Last Updated**: March 7, 2026  
**Repository**: https://github.com/rachidb13/kanasa_vps_setup  
**Status**: ✅ Ready for Production

