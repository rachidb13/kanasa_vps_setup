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

echo "✔ Port $KANASA_WG_PORT is free"

# ─────────────────────────────────────────────────────────────
# PATHS
# ─────────────────────────────────────────────────────────────
SERVICE_DIR="/opt/kanasa-wg"
BINARY_PATH="$SERVICE_DIR/kanasa-wg"
ENV_PATH="$SERVICE_DIR/.env"
SERVICE_PATH="/etc/systemd/system/kanasa-wg.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_URL="https://github.com/rachidb13/kanasa-wg/releases/latest/download/kanasa-wg"

echo "⚙️ Preparing Kanasa WG service..."

# ─────────────────────────────────────────────────────────────
# CREATE DIRECTORY
# ─────────────────────────────────────────────────────────────
mkdir -p "$SERVICE_DIR"

# ─────────────────────────────────────────────────────────────
# DOWNLOAD BINARY
# ─────────────────────────────────────────────────────────────
echo "⬇️ Downloading kanasa-wg binary..."
tmp_binary="$(mktemp)"

if curl -fsSL "$BINARY_URL" -o "$tmp_binary"; then
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
EOF
chmod 600 "$ENV_PATH"

# ─────────────────────────────────────────────────────────────
# INSTALL SYSTEMD SERVICE
# ─────────────────────────────────────────────────────────────
echo "🛠 Installing systemd service..."

# Check if template exists, fallback to generating it if missing
if [[ -f "$SCRIPT_DIR/kanasa-wg.service.tpl" ]]; then
  install -m 0644 "$SCRIPT_DIR/kanasa-wg.service.tpl" "$SERVICE_PATH"
else
  # Emergency fallback to prevent failure if tpl is missing
  cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Kanasa WireGuard Service
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
systemctl enable kanasa-wg
systemctl restart kanasa-wg

# ─────────────────────────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────────────────────────
echo "🔍 Checking service health..."
# Wait up to 10 seconds for the service to bind to the port
for _ in {1..10}; do
  if curl -fsS "http://127.0.0.1:${KANASA_WG_PORT}/health" >/dev/null 2>&1 \
     || wget -q --spider "http://127.0.0.1:${KANASA_WG_PORT}/health"; then
    echo "✔ Kanasa WG service ready"
    exit 0
  fi
  sleep 1
done

echo "❌ Health check failed"
echo "👉 Logs:"
journalctl -u kanasa-wg --no-pager -n 20
exit 1
