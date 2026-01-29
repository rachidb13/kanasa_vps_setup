echo "🔍 Checking environment..."
OS=$(lsb_release -si)
VERSION_ID=$(lsb_release -sr)

echo "OS: $OS $VERSION_ID"

# Check WireGuard availability
if command -v wg >/dev/null 2>&1; then
    WG_PRESENT=1
else
    WG_PRESENT=0
fi

# Ubuntu 20.04+ → OK
if [ "$OS" = "Ubuntu" ] && awk "BEGIN {exit !($VERSION_ID >= 20.04)}"; then
    echo "✔ Ubuntu $VERSION_ID supported"
    exit 0
fi

# Ubuntu 18.04 + WireGuard → allow
if [ "$OS" = "Ubuntu" ] && [ "$VERSION_ID" = "18.04" ] && [ "$WG_PRESENT" -eq 1 ]; then
    echo "⚠ Ubuntu 18.04 detected"
    echo "✔ WireGuard already installed"
    echo "✔ Proceeding (manual WG support assumed)"
    exit 0
fi

# Anything else → fail
echo "❌ Unsupported OS or missing WireGuard"
echo "Ubuntu 20.04+ recommended"
echo "Ubuntu 18.04 allowed ONLY if WireGuard is installed"
exit 1
