# kanasa-vps-setup

VPS provisioning for the Kanasa network.

## Usage

### Verbose Mode (default)

```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash
```

### Silent Mode

Add `KANASA_SILENT=1` for a clean, minimal-output installation:

```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
export KANASA_SILENT=1
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash
```

## Project Structure

```
kanasa-vps-setup/
├── README.md
├── run.sh
├── scripts/
│   ├── 00_common.sh
│   ├── 01_check_env.sh
│   ├── 02_wireguard.sh
│   ├── 04_wg_service.sh
│   └── 05_firewall.sh
```
