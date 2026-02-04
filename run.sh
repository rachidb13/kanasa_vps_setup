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

if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  echo "❌ KANASA_SERVER_KEY is required"
  echo "👉 Example:"
  echo "   export KANASA_SERVER_KEY=france-2"
  echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash"
  exit 1
fi

KANASA_WG_PORT="${KANASA_WG_PORT:-9000}"

if ! [[ "$KANASA_WG_PORT" =~ ^[0-9]+$ ]] || (( KANASA_WG_PORT < 1 || KANASA_WG_PORT > 65535 )); then
  echo "❌ Invalid KANASA_WG_PORT: $KANASA_WG_PORT"
  echo "👉 Port must be a number between 1 and 65535"
  exit 1
fi

echo "🔍 Checking availability of port $KANASA_WG_PORT..."
if ss -lnt "( sport = :$KANASA_WG_PORT )" | grep -q LISTEN; then
  echo ""
  echo "❌❌❌ PORT CONFLICT DETECTED ❌❌❌"
  echo ""
  echo "Port $KANASA_WG_PORT is already in use on this VPS."
  echo ""
  echo "👉 Please choose another port and re-run:"
  echo ""
  echo "   export KANASA_SERVER_KEY=${KANASA_SERVER_KEY}"
  echo "   export KANASA_WG_PORT=<FREE_PORT>"
  echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash"
  echo ""
  exit 1
fi
echo "✔ Port $KANASA_WG_PORT is free"

export KANASA_SERVER_KEY
export KANASA_WG_PORT

run_step "Environment check" "$SCRIPT_DIR/scripts/01_check_env.sh"
run_step "WireGuard install" "$SCRIPT_DIR/scripts/02_wireguard.sh"
run_step "Go install" "$SCRIPT_DIR/scripts/03_go.sh"
run_step "Kanasa WG service" "$SCRIPT_DIR/scripts/04_wg_service.sh"
run_step "Firewall setup" "$SCRIPT_DIR/scripts/05_firewall.sh"

echo ""
echo "✅ Kanasa VPS setup completed successfully"