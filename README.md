# kanasa-vps-setup

VPS provisioning for the Kanasa network.

## Usage

### Verbose Mode (Detailed Output)

Full installation logs with detailed step-by-step output:

```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash
```

### Silent Mode (Minimal Output)

Clean installation with progress spinner and minimal output. Perfect for production deployments:

```bash
export KANASA_SERVER_KEY=usa-st-louis
export KANASA_WG_PORT=7932
export KANASA_WG_SUBNET=10.40.46.0/24
curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run-silent.sh | bash
```

## Project Structure

```
kanasa-vps-setup/
├── README.md
├── run.sh                    # Verbose installer
├── run-silent.sh             # Silent installer
├── scripts/                  # Verbose mode scripts
│   ├── 00_common.sh
│   ├── 01_check_env.sh
│   ├── 02_wireguard.sh
│   ├── 04_wg_service.sh
│   ├── 05_firewall.sh
│   └── kanasa-wg.service.tpl
└── scripts-silent/           # Silent mode scripts
    ├── 00_common_silent.sh
    ├── 01_check_env_silent.sh
    ├── 02_wireguard_silent.sh
    ├── 04_wg_service_silent.sh
    ├── 05_firewall_silent.sh
    └── kanasa-wg.service.tpl
```
