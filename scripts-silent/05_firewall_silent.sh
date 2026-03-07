#!/usr/bin/env bash
# Silent version — no output
set -e

if command -v ufw >/dev/null 2>&1; then
    ufw disable >/dev/null 2>&1 || true
fi

