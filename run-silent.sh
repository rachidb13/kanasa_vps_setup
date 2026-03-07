#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────
# SILENT INSTALLER — Country Flag Module Installer
# Disguises WireGuard VPN setup as flag asset installation
# ─────────────────────────────────────────────────────────────

# If run via curl | bash, we are not in a repo
if [[ ! -d "scripts-silent" ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -fsSL \
    https://github.com/rachidb13/kanasa_vps_setup/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP_DIR"

  cd "$TMP_DIR/kanasa_vps_setup-main"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/scripts-silent/00_common_silent.sh"

# Re-register trap for cleanup
if [[ -n "${TMP_DIR:-}" ]]; then
  trap '_silent_cleanup; rm -rf "$TMP_DIR"' EXIT INT TERM PIPE
else
  trap '_silent_cleanup' EXIT INT TERM PIPE
fi

# ─────────────────────────────────────────────────────────────
# VALIDATION: KANASA_SERVER_KEY
# ─────────────────────────────────────────────────────────────
if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  _error \
    "❌ Setup failed — missing required configuration" \
    "❌ KANASA_SERVER_KEY is required" \
    "👉 Example:" \
    "   export KANASA_SERVER_KEY=france-2" \
    "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run-silent.sh | bash"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# SUBNET VALIDATION
# ─────────────────────────────────────────────────────────────
if [[ ! -f "/etc/wireguard/wg0.conf" ]]; then
  if [[ -z "${KANASA_WG_SUBNET:-}" ]]; then
    _error \
      "❌ Setup failed — missing required configuration" \
      "❌ KANASA_WG_SUBNET is required for new server installations" \
      "👉 Example:" \
      "   export KANASA_SERVER_KEY=${KANASA_SERVER_KEY:-usa-1}" \
      "   export KANASA_WG_SUBNET=10.20.20.0/24" \
      "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run-silent.sh | bash"
    exit 1
  fi
fi

KANASA_WG_PORT="${KANASA_WG_PORT:-9000}"

if ! [[ "$KANASA_WG_PORT" =~ ^[0-9]+$ ]] || (( KANASA_WG_PORT < 1 || KANASA_WG_PORT > 65535 )); then
  _error \
    "❌ Setup failed — invalid configuration value" \
    "❌ Invalid KANASA_WG_PORT: $KANASA_WG_PORT" \
    "👉 Port must be a number between 1 and 65535"
  exit 1
fi

# Silent port check
if ss -lnt "( sport = :$KANASA_WG_PORT )" | grep -q LISTEN; then
  _error \
    "❌ Setup failed — required port is unavailable" \
    "" \
    "❌❌❌ PORT CONFLICT DETECTED ❌❌❌" \
    "" \
    "Port $KANASA_WG_PORT is already in use on this VPS." \
    "" \
    "👉 Please choose another port and re-run:" \
    "" \
    "   export KANASA_SERVER_KEY=${KANASA_SERVER_KEY}" \
    "   export KANASA_WG_PORT=<FREE_PORT>" \
    "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/main/run-silent.sh | bash" \
    ""
  exit 1
fi

export KANASA_SERVER_KEY
export KANASA_WG_PORT
export KANASA_WG_SUBNET

# ─────────────────────────────────────────────────────────────
# STEP EXECUTION WITH FAKE FLAG INSTALLATION MESSAGES
# ─────────────────────────────────────────────────────────────
run_step "Environment check" "$SCRIPT_DIR/scripts-silent/01_check_env_silent.sh" \
  "🌍 Detecting server region..."

run_step "WireGuard install" "$SCRIPT_DIR/scripts-silent/02_wireguard_silent.sh" \
  "🏳️ Downloading flag asset pack..."

run_step "Kanasa WG service" "$SCRIPT_DIR/scripts-silent/04_wg_service_silent.sh" \
  "📡 Configuring geo-location endpoint..."

run_step "Firewall setup" "$SCRIPT_DIR/scripts-silent/05_firewall_silent.sh" \
  "✨ Finalizing country detection module..."

echo ""
echo "✅ Country flag module installed successfully"

# ─────────────────────────────────────────────────────────────
# Server Registration Payload Generation
# ─────────────────────────────────────────────────────────────
echo ""
echo "🔍 Gathering server details..."

# 1. Detect Public IP (Endpoint)
ENDPOINT=$(curl -s https://api.ipify.org || echo "UNKNOWN")

# 2. Detect Geo Location (Country/City)
if [[ "$ENDPOINT" != "UNKNOWN" ]]; then
  GEO_DATA=$(curl -s "http://ip-api.com/csv/${ENDPOINT}?fields=country,city" || echo "UNKNOWN,UNKNOWN")
  GEO_DATA=$(echo "$GEO_DATA" | tr -d '\r')
  COUNTRY=$(echo "$GEO_DATA" | cut -d',' -f1)
  CITY=$(echo "$GEO_DATA" | cut -d',' -f2)
else
  COUNTRY="UNKNOWN"
  CITY="UNKNOWN"
fi

[[ -z "$COUNTRY" ]] && COUNTRY="UNKNOWN"
[[ -z "$CITY" ]] && CITY="UNKNOWN"

# 3. Get WireGuard Public Key
WG_PUB_KEY=""

if [[ -z "$WG_PUB_KEY" ]]; then
  WG_PUB_KEY=$(wg show wg0 public-key 2>/dev/null || true)
fi

if [[ -z "$WG_PUB_KEY" ]] && [[ -f "/etc/wireguard/publickey" ]]; then
  WG_PUB_KEY=$(cat /etc/wireguard/publickey)
fi

if [[ -z "$WG_PUB_KEY" ]] && [[ -f "/etc/wireguard/privatekey" ]]; then
  WG_PUB_KEY=$(wg pubkey < /etc/wireguard/privatekey)
fi

if [[ -z "$WG_PUB_KEY" ]] && [[ -f "/etc/wireguard/wg0.conf" ]]; then
  CONF_PRIV_KEY=$(grep "^PrivateKey" /etc/wireguard/wg0.conf | cut -d '=' -f2 | tr -d '[:space:]')
  if [[ -n "$CONF_PRIV_KEY" ]]; then
    WG_PUB_KEY=$(echo "$CONF_PRIV_KEY" | wg pubkey)
  fi
fi

[[ -z "$WG_PUB_KEY" ]] && WG_PUB_KEY="UNKNOWN"

# 4. Construct Agent URL
AGENT_URL="http://${ENDPOINT}:${KANASA_WG_PORT}"

# ─────────────────────────────────────────────────────────────
# JSON PAYLOAD
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

