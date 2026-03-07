#!/usr/bin/env bash
# Silent version — no output
set -e

# 1. Install WireGuard tools if missing
if ! command -v wg >/dev/null 2>&1; then
  apt-get update -qq >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a apt-get install -y wireguard wireguard-tools iptables >/dev/null 2>&1
fi

# 2. Enable IP Forwarding
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-kanasa.conf
sysctl -p /etc/sysctl.d/99-kanasa.conf > /dev/null 2>&1

if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
  exit 1
fi

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# 3. Idempotency Check
if [[ -f "/etc/wireguard/wg0.conf" ]]; then
  if ! ip link show wg0 >/dev/null 2>&1; then
    systemctl enable wg-quick@wg0 >/dev/null 2>&1
    systemctl restart wg-quick@wg0 >/dev/null 2>&1
  fi
  exit 0
fi

# 4. Bootstrap Logic
if [[ -z "${KANASA_WG_SUBNET:-}" ]]; then
  exit 1
fi

# Derive IP Address
WG_ADDRESS=$(echo "$KANASA_WG_SUBNET" | sed 's/\.0\//.1\//')

if [[ "$WG_ADDRESS" == "$KANASA_WG_SUBNET" ]]; then
  exit 1
fi

# Generate Keys
if [[ ! -f "/etc/wireguard/privatekey" ]]; then
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey 2>/dev/null
fi
PRIVATE_KEY=$(cat /etc/wireguard/privatekey)

# Detect WAN Interface
DEFAULT_IF=$(ip route show default | awk '/default/ {print $5}' | head -n1)
[[ -z "$DEFAULT_IF" ]] && DEFAULT_IF="eth0"

# Create wg0.conf
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = $WG_ADDRESS
ListenPort = 51820
PrivateKey = $PRIVATE_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $DEFAULT_IF -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $DEFAULT_IF -j MASQUERADE
EOF
chmod 600 /etc/wireguard/wg0.conf

# 5. Enable and Start
systemctl enable wg-quick@wg0 >/dev/null 2>&1
systemctl restart wg-quick@wg0 >/dev/null 2>&1

# 6. Verification
if ! wg show wg0 >/dev/null 2>&1; then
  exit 1
fi

