#!/bin/bash
set -e

echo "🔥 Firewall setup (OPEN MODE)"

if command -v ufw >/dev/null 2>&1; then
    echo "Disabling UFW completely"
    ufw disable || true
else
    echo "UFW not installed — nothing to do"
fi

echo "✔ Firewall disabled (all ports open)"
