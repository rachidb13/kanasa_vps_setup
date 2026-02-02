#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${KANASA_SERVER_KEY:-}" ]]; then
  echo "❌ KANASA_SERVER_KEY is required"
  exit 1
fi

SERVICE_DIR="/opt/kanasa-wg"
BINARY_PATH="$SERVICE_DIR/kanasa-wg"
ENV_PATH="$SERVICE_DIR/.env"
SERVICE_PATH="/etc/systemd/system/kanasa-wg.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_URL="https://github.com/rachidb13/kanasa-wg/releases/latest/download/kanasa-wg"

echo "⚙️ Preparing Kanasa WG service..."

mkdir -p "$SERVICE_DIR"

echo "⬇️ Downloading kanasa-wg binary..."
tmp_binary="$(mktemp)"

if command -v wget >/dev/null 2>&1; then
  wget -q -O "$tmp_binary" "$BINARY_URL"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "$tmp_binary" "$BINARY_URL"
else
  echo "❌ curl or wget is required"
  exit 1
fi

install -m 0755 "$tmp_binary" "$BINARY_PATH"
rm -f "$tmp_binary"

echo "🔐 Writing environment file..."
echo "KANASA_SERVER_KEY=${KANASA_SERVER_KEY}" > "$ENV_PATH"
chmod 600 "$ENV_PATH"

echo "🛠 Installing systemd service..."
install -m 0644 "$SCRIPT_DIR/kanasa-wg.service.tpl" "$SERVICE_PATH"

systemctl daemon-reload
systemctl enable kanasa-wg
systemctl restart kanasa-wg

echo "🔍 Checking service health..."
for _ in {1..10}; do
  if curl -fsS http://127.0.0.1:9000/health >/dev/null 2>&1 \
     || wget -q --spider http://127.0.0.1:9000/health; then
    echo "✔ Kanasa WG service ready"
    exit 0
  fi
  sleep 1
done

echo "❌ Health check failed"
exit 1
