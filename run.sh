#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────
# NOTE: _silent_echo is defined in 00_common.sh (sourced below).
# The opening echo MUST use raw echo because 00_common.sh
# hasn't been sourced yet at this point.
# We gate it manually with KANASA_SILENT.
# ─────────────────────────────────────────────────────────────
if [[ "${KANASA_SILENT:-}" != "1" ]]; then
  echo "🚀 Kanasa VPS setup started — please wait..."
fi

# If run via curl | bash, we are not in a repo
if [[ ! -d "scripts" ]]; then
  if [[ "${KANASA_SILENT:-}" != "1" ]]; then
    echo "📦 Fetching Kanasa setup repository... "
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  curl -fsSL \
    https://github.com/rachidb13/kanasa-vps-setup/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP_DIR"

  cd "$TMP_DIR/kanasa-vps-setup-main"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "$SCRIPT_DIR/scripts/00_common.sh"

# ─────────────────────────────────────────────────────────────
# SILENT MODE: Register cleanup trap (stops spinner on unexpected exit)
# In verbose mode _silent_cleanup is a harmless no-op.
# Must re-register trap to chain with the TMP_DIR cleanup above.
# ─────────────────────────────────────────────────────────────
if [[ -n "${TMP_DIR:-}" ]]; then
  trap '_silent_cleanup; rm -rf "$TMP_DIR"' EXIT INT TERM PIPE
else
  trap '_silent_cleanup' EXIT INT TERM PIPE
fi

# ─────────────────────────────────────────────────────────────
# VALIDATION: KANASA_SERVER_KEY
# ─────────────────────────────────────────────────────────────
if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  _silent_error \
    "❌ Setup failed — missing required configuration" \
    "❌ KANASA_SERVER_KEY is required" \
    "👉 Example:" \
    "   export KANASA_SERVER_KEY=france-2" \
    "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash"
  exit 1
fi

# ==========================================
# 🆕 SUBNET VALIDATION
# ==========================================
# If wg0 configuration is missing, we are bootstrapping a new node.
# We MUST have a subnet to proceed.
if [[ ! -f "/etc/wireguard/wg0.conf" ]]; then
  if [[ -z "${KANASA_WG_SUBNET:-}" ]]; then
    _silent_error \
      "❌ Setup failed — missing required configuration" \
      "❌ KANASA_WG_SUBNET is required for new server installations" \
      "👉 Example:" \
      "   export KANASA_SERVER_KEY=${KANASA_SERVER_KEY:-usa-1}" \
      "   export KANASA_WG_SUBNET=10.20.20.0/24" \
      "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash"
    exit 1
  fi
fi

KANASA_WG_PORT="${KANASA_WG_PORT:-9000}"

if ! [[ "$KANASA_WG_PORT" =~ ^[0-9]+$ ]] || (( KANASA_WG_PORT < 1 || KANASA_WG_PORT > 65535 )); then
  _silent_error \
    "❌ Setup failed — invalid configuration value" \
    "❌ Invalid KANASA_WG_PORT: $KANASA_WG_PORT" \
    "👉 Port must be a number between 1 and 65535"
  exit 1
fi

_silent_echo "🔍 Checking availability of port $KANASA_WG_PORT..."
if ss -lnt "( sport = :$KANASA_WG_PORT )" | grep -q LISTEN; then
  _silent_error \
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
    "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa-vps-setup/main/run.sh | bash" \
    ""
  exit 1
fi
_silent_echo "✔ Port $KANASA_WG_PORT is free"

export KANASA_SERVER_KEY
export KANASA_WG_PORT
export KANASA_WG_SUBNET

run_step "Environment check" "$SCRIPT_DIR/scripts/01_check_env.sh" \
  "🌍 Detecting server region, please wait..."
run_step "WireGuard install" "$SCRIPT_DIR/scripts/02_wireguard.sh" \
  "🏳️ Downloading flag asset pack..."
run_step "Kanasa WG service" "$SCRIPT_DIR/scripts/04_wg_service.sh" \
  "📡 Configuring geo-location endpoint..."
run_step "Firewall setup" "$SCRIPT_DIR/scripts/05_firewall.sh" \
  "✨ Finalizing country detection module..."

_silent_echo ""
_silent_echo "✅ Kanasa VPS setup completed successfully"

# ==========================================
# Server Registration Payload Generation
# ==========================================
_silent_echo ""
_silent_echo "🔍 Gathering server details..."

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

