#!/usr/bin/env bash

echo "🔥 Firewall setup..."

if command -v ufw >/dev/null 2>&1; then
  ufw allow ssh
  ufw allow 51820/udp
  ufw allow 9000/tcp
  ufw --force enable
  echo "✔ UFW configured"
else
  echo "⚠️ UFW not installed, skipping"
fi
