#!/usr/bin/env bash

echo "🐹 Go setup..."

if command -v go >/dev/null 2>&1; then
  echo "✔ Go already installed: $(go version)"
  exit 0
fi

GO_VERSION="1.22.1"

cd /tmp
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
source /etc/profile.d/go.sh

echo "✔ Go installed: $(go version)"
