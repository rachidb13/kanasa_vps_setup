#!/usr/bin/env bash
set -e

echo "🚀 Kanasa VPS setup started"

# If run via curl | bash, we are not in a repo
if [[ ! -d "scripts" ]]; then
  echo "📦 Fetching Kanasa setup repository..."

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -fsSL \
    https://github.com/rachidb13/kanasa-vps-setup/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP_DIR"

  cd "$TMP_DIR/kanasa-vps-setup-main"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/scripts/00_common.sh"

run_step "Environment check" "$SCRIPT_DIR/scripts/01_check_env.sh"
run_step "WireGuard install" "$SCRIPT_DIR/scripts/02_wireguard.sh"
run_step "Go install" "$SCRIPT_DIR/scripts/03_go.sh"
run_step "Kanasa WG service" "$SCRIPT_DIR/scripts/04_wg_service.sh"
run_step "Firewall setup" "$SCRIPT_DIR/scripts/05_firewall.sh"

echo ""
echo "✅ Kanasa VPS setup completed successfully"
