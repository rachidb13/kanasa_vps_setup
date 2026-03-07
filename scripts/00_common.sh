#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root (sudo)"
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# MAIN: run_step — verbose step runner
# ─────────────────────────────────────────────────────────────
run_step() {
  local name="$1"
  local script="$2"

  if [[ ! -f "$script" ]]; then
    echo "❌ Missing script: $script"
    exit 1
  fi

  echo ""
  echo "=============================="
  echo "▶ $name"
  echo "=============================="
  bash "$script"
  echo "✔ $name completed"
}
