#!/usr/bin/env bash
# Silent version — no output
set -euo pipefail

if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  exit 1
fi

KANASA_WG_PORT="${KANASA_WG_PORT:-9000}"

if ! [[ "$KANASA_WG_PORT" =~ ^[0-9]+$ ]] || (( KANASA_WG_PORT < 1 || KANASA_WG_PORT > 65535 )); then
  exit 1
fi

# Check port availability
if ss -lnt "( sport = :$KANASA_WG_PORT )" | grep -q LISTEN; then
  exit 1
fi

# Paths
SERVICE_DIR="/opt/kanasa-wg"
BINARY_PATH="$SERVICE_DIR/kanasa-wg"
ENV_PATH="$SERVICE_DIR/.env"
SERVICE_PATH="/etc/systemd/system/kanasa-wg.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_URL="https://github.com/rachidb13/kanasa-wg/releases/latest/download/kanasa-wg"

mkdir -p "$SERVICE_DIR"

# Download binary
tmp_binary="$(mktemp)"
if curl -fsSL "$BINARY_URL" -o "$tmp_binary" 2>/dev/null; then
  chmod +x "$tmp_binary"
  mv "$tmp_binary" "$BINARY_PATH"
else
  rm -f "$tmp_binary"
  exit 1
fi

# Create configuration
cat <<EOF > "$ENV_PATH"
PORT=${KANASA_WG_PORT}
KANASA_WG_PORT=${KANASA_WG_PORT}
KANASA_SERVER_KEY=${KANASA_SERVER_KEY}
EOF
chmod 600 "$ENV_PATH"

# Install systemd service
if [[ -f "$SCRIPT_DIR/kanasa-wg.service.tpl" ]]; then
  install -m 0644 "$SCRIPT_DIR/kanasa-wg.service.tpl" "$SERVICE_PATH"
else
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

systemctl daemon-reload >/dev/null 2>&1
systemctl enable kanasa-wg >/dev/null 2>&1
systemctl restart kanasa-wg >/dev/null 2>&1

# Health check
for _ in {1..10}; do
  if curl -fsS "http://127.0.0.1:${KANASA_WG_PORT}/health" >/dev/null 2>&1 \
     || wget -q --spider "http://127.0.0.1:${KANASA_WG_PORT}/health" 2>/dev/null; then
    exit 0
  fi
  sleep 1
done

exit 1

