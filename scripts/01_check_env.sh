#!/usr/bin/env bash

echo "🔍 Checking environment..."

if [[ ! -f /etc/os-release ]]; then
  echo "❌ Unsupported OS"
  exit 1
fi

source /etc/os-release

echo "OS: $NAME $VERSION_ID"

if [[ "$ID" != "ubuntu" ]]; then
  echo "❌ Only Ubuntu is supported for now"
  exit 1
fi

if [[ "$VERSION_ID" < "20.04" ]]; then
  echo "❌ Ubuntu 20.04+ required"
  exit 1
fi

echo "✔ Environment OK"
