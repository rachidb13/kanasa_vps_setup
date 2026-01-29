#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Kanasa VPS setup started"

source "$SCRIPT_DIR/scripts/00_common.sh"

run_step "Environment check" "$SCRIPT_DIR/scripts/01_check_env.sh"
run_step "WireGuard setup"     "$SCRIPT_DIR/scripts/02_wireguard.sh"
run_step "Go install"          "$SCRIPT_DIR/scripts/03_go.sh"
run_step "WG Go service"       "$SCRIPT_DIR/scripts/04_wg_service.sh"
run_step "Firewall rules"      "$SCRIPT_DIR/scripts/05_firewall.sh"

echo "✅ Kanasa VPS setup completed successfully"
