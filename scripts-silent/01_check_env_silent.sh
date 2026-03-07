#!/usr/bin/env bash
# Silent version — no output
set -e

OS=$(lsb_release -si 2>/dev/null)
VERSION_ID=$(lsb_release -sr 2>/dev/null)

# Check WireGuard availability
if command -v wg >/dev/null 2>&1; then
    WG_PRESENT=1
else
    WG_PRESENT=0
fi

# Ubuntu 20.04+ → OK
if [ "$OS" = "Ubuntu" ] && awk "BEGIN {exit !($VERSION_ID >= 20.04)}"; then
    exit 0
fi

# Ubuntu 18.04 + WireGuard → allow
if [ "$OS" = "Ubuntu" ] && [ "$VERSION_ID" = "18.04" ] && [ "$WG_PRESENT" -eq 1 ]; then
    exit 0
fi

# Anything else → fail
exit 1

