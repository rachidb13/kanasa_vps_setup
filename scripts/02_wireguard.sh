#!/usr/bin/env bash
set -e

echo "🔐 WireGuard setup..."

# 1. Install WireGuard tools if missing
if command -v wg >/dev/null 2>&1; then
  echo "✔ WireGuard already installed"
else
  echo "📦 Installing WireGuard..."
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard wireguard-tools iptables
fi

# 2. Enable IP Forwarding (Critical for VPN routing)
echo "🌐 Enabling IPv4 forwarding..."

# Persist settings to a dedicated file to avoid conflicts
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-kanasa.conf

# Apply settings immediately
sysctl -p /etc/sysctl.d/99-kanasa.conf > /dev/null

# Strict Verification
if [[ "$(sysctl -n net.ipv4.ip_forward)" != "1" ]]; then
  echo "❌ Failed to enable IP forwarding"
  exit 1
fi
echo "✔ net.ipv4.ip_forward = 1"

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

# 3. Idempotency Check: If wg0.conf exists, we assume this VPS is already configured.
if [[ -f "/etc/wireguard/wg0.conf" ]]; then
  echo "✔ WireGuard configuration already exists. Skipping bootstrap."

  # Ensure it is running
  if ! ip link show wg0 >/dev/null 2>&1; then
    echo "🔄 Interface wg0 down. Starting..."
    systemctl enable wg-quick@wg0
    systemctl restart wg-quick@wg0
  fi

  echo "✔ WireGuard ready"
  exit 0
fi

# 4. Bootstrap Logic for New Installs
echo "⚙️ Bootstrapping WireGuard interface..."

# Validate Subnet (passed from run.sh)
if [[ -z "${KANASA_WG_SUBNET:-}" ]]; then
  echo "❌ KANASA_WG_SUBNET is required to bootstrap a new server."
  exit 1
fi

# Derive IP Address: 10.20.20.0/24 -> 10.20.20.1/24
# We simply replace the ending .0/ with .1/
WG_ADDRESS=$(echo "$KANASA_WG_SUBNET" | sed 's/\.0\//.1\//')

if [[ "$WG_ADDRESS" == "$KANASA_WG_SUBNET" ]]; then
  echo "❌ Failed to derive server IP. Ensure subnet ends in .0/XX (e.g., 10.20.20.0/24)"
  exit 1
fi
echo "🔹 Derived Server IP: $WG_ADDRESS"

# Generate Keys (Idempotent)
if [[ ! -f "/etc/wireguard/privatekey" ]]; then
  echo "🔑 Generating new WireGuard keys..."
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
fi
PRIVATE_KEY=$(cat /etc/wireguard/privatekey)

# Detect WAN Interface for NAT (e.g., eth0, ens3)
DEFAULT_IF=$(ip route show default | awk '/default/ {print $5}' | head -n1)
[[ -z "$DEFAULT_IF" ]] && DEFAULT_IF="eth0"
echo "🔹 Detected WAN interface: $DEFAULT_IF"

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
echo "✔ Created /etc/wireguard/wg0.conf"

# 5. Enable and Start
echo "🚀 Starting WireGuard..."
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

# 6. Verification
if wg show wg0 >/dev/null 2>&1; then
  echo "✔ WireGuard interface (wg0) is UP"
else
  echo "❌ Failed to bring up wg0"
  exit 1
fi

echo "✔ WireGuard ready"