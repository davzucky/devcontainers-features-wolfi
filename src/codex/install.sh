#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}

apk update
apk add --no-cache ca-certificates git ripgrep bubblewrap

echo "Installing Codex with mise (${VERSION})"
mise install --system "codex@${VERSION#v}"
mise use --pin --path /etc/mise/conf.d/codex.toml "codex@${VERSION#v}"
mise reshim --system
export PATH="/usr/local/share/mise/shims:${PATH}"
command -v codex
codex --version

echo "Codex installed successfully"
