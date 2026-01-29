#!/usr/bin/env bash

set -e

if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run as root (sudo)"
  exit 1
fi

run_step() {
  local name="$1"
  local script="$2"

  echo ""
  echo "=============================="
  echo "▶ $name"
  echo "=============================="

  if [[ ! -f "$script" ]]; then
    echo "❌ Missing script: $script"
    exit 1
  fi

  bash "$script"

  echo "✔ $name completed"
}
