#!/usr/bin/env bash
set -e

echo "🚀 Kanasa VPS setup started"

# If run via curl | bash, we are not in a repo
if [[ ! -d "scripts" ]]; then
  echo "📦 Fetching Kanasa setup repository..."

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -fsSL \
    https://github.com/rachidb13/kanasa_vps_setup/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP_DIR"

  cd "$TMP_DIR/kanasa_vps_setup-main"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/scripts/00_common.sh"


# ─────────────────────────────────────────────────────────────
# VALIDATION: KANASA_SERVER_KEY
# ─────────────────────────────────────────────────────────────
if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  echo "❌ KANASA_SERVER_KEY is required"
  echo "👉 Example:"
  echo "   export KANASA_SERVER_KEY=france-2"
  echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run.sh | bash"
  exit 1
fi

# ==========================================
# 🆕 SUBNET VALIDATION
# ==========================================
# If wg0 configuration is missing, we are bootstrapping a new node.
# We MUST have a subnet to proceed.
if [[ ! -f "/etc/wireguard/wg0.conf" ]]; then
  if [[ -z "${KANASA_WG_SUBNET:-}" ]]; then
    echo "❌ KANASA_WG_SUBNET is required for new server installations"
    echo "👉 Example:"
    echo "   export KANASA_SERVER_KEY=${KANASA_SERVER_KEY:-usa-1}"
    echo "   export KANASA_WG_SUBNET=10.20.20.0/24"
    echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run.sh | bash"
    exit 1
  fi
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
  echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run.sh | bash"
  echo ""
  exit 1
fi
echo "✔ Port $KANASA_WG_PORT is free"

export KANASA_SERVER_KEY
export KANASA_WG_PORT
export KANASA_WG_SUBNET

run_step "Environment check" "$SCRIPT_DIR/scripts/01_check_env.sh"
run_step "WireGuard install" "$SCRIPT_DIR/scripts/02_wireguard.sh"
run_step "Kanasa WG service" "$SCRIPT_DIR/scripts/04_wg_service.sh"
run_step "Firewall setup" "$SCRIPT_DIR/scripts/05_firewall.sh"

echo ""
echo "✅ Kanasa VPS setup completed successfully"

# ==========================================
# Server Registration Payload Generation
# ==========================================
echo ""
echo "🔍 Gathering server details..."

# 1. Detect Public IP (Endpoint)
ENDPOINT=$(curl -s https://api.ipify.org || echo "UNKNOWN")

# 2. Detect Geo Location (Country/City)
# Using ip-api csv format to avoid JSON parsing dependencies
if [[ "$ENDPOINT" != "UNKNOWN" ]]; then
  GEO_DATA=$(curl -s "http://ip-api.com/csv/${ENDPOINT}?fields=country,city" || echo "UNKNOWN,UNKNOWN")
  # Remove carriage returns just in case
  GEO_DATA=$(echo "$GEO_DATA" | tr -d '\r')
  COUNTRY=$(echo "$GEO_DATA" | cut -d',' -f1)
  CITY=$(echo "$GEO_DATA" | cut -d',' -f2)
else
  COUNTRY="UNKNOWN"
  CITY="UNKNOWN"
fi

# Fallback checks for empty strings
[[ -z "$COUNTRY" ]] && COUNTRY="UNKNOWN"
[[ -z "$CITY" ]] && CITY="UNKNOWN"

# 3. Get WireGuard Public Key (Robust Detection)
WG_PUB_KEY=""

# Method A: Ask running WireGuard interface
if [[ -z "$WG_PUB_KEY" ]]; then
  WG_PUB_KEY=$(wg show wg0 public-key 2>/dev/null || true)
fi

# Method B: Read standard public key file
if [[ -z "$WG_PUB_KEY" ]] && [[ -f "/etc/wireguard/publickey" ]]; then
  WG_PUB_KEY=$(cat /etc/wireguard/publickey)
fi

# Method C: Derive from private key file
if [[ -z "$WG_PUB_KEY" ]] && [[ -f "/etc/wireguard/privatekey" ]]; then
  WG_PUB_KEY=$(wg pubkey < /etc/wireguard/privatekey)
fi

# Method D: Extract from wg0.conf and derive
if [[ -z "$WG_PUB_KEY" ]] && [[ -f "/etc/wireguard/wg0.conf" ]]; then
  # Extract PrivateKey value, ignoring whitespace
  CONF_PRIV_KEY=$(grep "^PrivateKey" /etc/wireguard/wg0.conf | cut -d '=' -f2 | tr -d '[:space:]')
  if [[ -n "$CONF_PRIV_KEY" ]]; then
    WG_PUB_KEY=$(echo "$CONF_PRIV_KEY" | wg pubkey)
  fi
fi

# Fallback if all fail
[[ -z "$WG_PUB_KEY" ]] && WG_PUB_KEY="UNKNOWN"


# 4. Construct Agent URL
AGENT_URL="http://${ENDPOINT}:${KANASA_WG_PORT}"

# ─────────────────────────────────────────────────────────────
# JSON PAYLOAD — always shown regardless of mode (FR-006)
# ─────────────────────────────────────────────────────────────
echo ""
echo "========================================================"
echo "       📝 SERVER REGISTRATION PAYLOAD 📝"
echo "========================================================"
echo "Copy the JSON block below and paste it into the admin panel:"
echo ""
cat <<EOF
{
  "server_key": "${KANASA_SERVER_KEY}",
  "country": "${COUNTRY}",
  "city": "${CITY}",
  "endpoint": "${ENDPOINT}",
  "agent_url": "${AGENT_URL}",
  "public_key": "${WG_PUB_KEY}",
  "listen_port": ${KANASA_WG_PORT}
}
EOF
echo ""
echo "========================================================"

