#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# REQUIRE SERVER KEY
# ─────────────────────────────────────────────────────────────
if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  echo "❌ KANASA_SERVER_KEY is required"
  echo "👉 Example:"
  echo "   export KANASA_SERVER_KEY=france-2"
  echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# WG PORT (DEFAULT = 9000)
# ─────────────────────────────────────────────────────────────
KANASA_WG_PORT="${KANASA_WG_PORT:-9000}"

# Validate port number
if ! [[ "$KANASA_WG_PORT" =~ ^[0-9]+$ ]] || (( KANASA_WG_PORT < 1 || KANASA_WG_PORT > 65535 )); then
  echo "❌ Invalid KANASA_WG_PORT: $KANASA_WG_PORT"
  echo "👉 Port must be a number between 1 and 65535"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# CHECK PORT AVAILABILITY
# ─────────────────────────────────────────────────────────────
echo "🔍 Checking availability of port $KANASA_WG_PORT..."

if ss -lnt "( sport = :$KANASA_WG_PORT )" | grep -q LISTEN; then
  if systemctl is-active --quiet oscam-checker; then
    echo "✔ Port $KANASA_WG_PORT is already used by oscam-checker; continuing with upgrade"
  else
    echo ""
    echo "❌❌❌ PORT CONFLICT DETECTED ❌❌❌"
    echo ""
    echo "Port $KANASA_WG_PORT is already in use on this VPS."
    echo ""
    echo "👉 Please choose another port and re-run:"
    echo ""
    echo "   export KANASA_SERVER_KEY=${KANASA_SERVER_KEY}"
    echo "   export KANASA_WG_PORT=<FREE_PORT>"
    echo "   curl -fsSL https://raw.githubusercontent.com/rachidb13/kanasa_vps_setup/001-silent-installer-mode/run.sh | bash"
    echo ""
    exit 1
  fi
else
  echo "✔ Port $KANASA_WG_PORT is free"
fi

# ─────────────────────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────────────────────
SERVICE_DIR="/opt/oscam-agent/oscam-checker"
BINARY_PATH="$SERVICE_DIR/oscam-checker"
ENV_PATH="$SERVICE_DIR/.env"
SERVICE_PATH="/etc/systemd/system/oscam-checker.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "⚙️ Preparing oscam-checker service..."

# ─────────────────────────────────────────────────────────────
# CREATE DIRECTORY
# ─────────────────────────────────────────────────────────────
mkdir -p "$SERVICE_DIR"

# ─────────────────────────────────────────────────────────────
# DOWNLOAD BINARY
# ─────────────────────────────────────────────────────────────
echo "⬇️ Resolving latest oscam-checker binary..."
LATEST_URL=$(curl -s https://api.github.com/repos/rachidb13/oscam-checker/releases/latest | grep browser_download_url | grep oscam-checker | cut -d '"' -f 4 || true)
if [[ -z "$LATEST_URL" ]]; then
  echo "❌ Failed to resolve latest oscam-checker release asset"
  exit 1
fi

echo "⬇️ Downloading oscam-checker binary..."
tmp_binary="$(mktemp)"

if curl -fsSL "$LATEST_URL" -o "$tmp_binary"; then
  chmod +x "$tmp_binary"
  mv "$tmp_binary" "$BINARY_PATH"
  echo "✔ Binary downloaded"
else
  echo "❌ Failed to download binary"
  rm -f "$tmp_binary"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# CREATE CONFIGURATION
# ─────────────────────────────────────────────────────────────
echo "📝 Creating configuration..."
# We explicitly set both PORT and KANASA_WG_PORT to ensure the binary picks it up
cat <<EOF > "$ENV_PATH"
PORT=${KANASA_WG_PORT}
KANASA_WG_PORT=${KANASA_WG_PORT}
KANASA_SERVER_KEY=${KANASA_SERVER_KEY}
KANASA_API_BASE_URL=${KANASA_API_BASE_URL:-https://api.kanasavpn.com}
EOF
chmod 600 "$ENV_PATH"

# ─────────────────────────────────────────────────────────────
# INSTALL SYSTEMD SERVICE
# ─────────────────────────────────────────────────────────────
echo "🛠 Installing systemd service..."

# Check if template exists, fallback to generating it if missing
if [[ -f "$SCRIPT_DIR/oscam-checker.service.tpl" ]]; then
  install -m 0644 "$SCRIPT_DIR/oscam-checker.service.tpl" "$SERVICE_PATH"
else
  # Emergency fallback to prevent failure if tpl is missing
  cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Oscam Checker Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$SERVICE_DIR
ExecStart=$BINARY_PATH
EnvironmentFile=$ENV_PATH
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 "$SERVICE_PATH"
fi

systemctl daemon-reload
systemctl enable oscam-checker
systemctl restart oscam-checker

# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────
echo "🔍 Checking service health..."
# Wait up to 10 seconds for the service to bind to the port
for _ in {1..10}; do
  if curl -fsS "http://127.0.0.1:${KANASA_WG_PORT}/health" >/dev/null 2>&1 \
     || wget -q --spider "http://127.0.0.1:${KANASA_WG_PORT}/health"; then
    echo "✔ oscam-checker service ready"
    exit 0
  fi
  sleep 1
done

echo "❌ Health check failed"
echo "👉 Logs:"
journalctl -u oscam-checker --no-pager -n 20
exit 1
