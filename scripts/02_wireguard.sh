#!/usr/bin/env bash

echo "🔐 WireGuard setup..."

if command -v wg >/dev/null 2>&1; then
  echo "✔ WireGuard already installed"
else
  echo "📦 Installing WireGuard..."
  apt update
  apt install -y wireguard wireguard-tools
fi

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

echo "✔ WireGuard ready"
