#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}

echo "Installing prek..."

apk update

if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    apk add --no-cache uv
fi

export UV_TOOL_BIN_DIR=/usr/bin
export UV_TOOL_DIR=/usr/lib/uv/tools

mkdir -p "${UV_TOOL_DIR}"

if [ "${VERSION}" = "latest" ]; then
    uv tool install --reinstall prek
else
    uv tool install --reinstall "prek==${VERSION}"
fi

if ! command -v prek >/dev/null 2>&1; then
    echo "prek installation failed"
    exit 1
fi

if [ "$(command -v prek)" != "/usr/bin/prek" ]; then
    echo "prek was not installed globally to /usr/bin"
    exit 1
fi

if [ "$(uv tool dir)" != "/usr/lib/uv/tools" ]; then
    echo "uv tool directory was not set to /usr/lib/uv/tools"
    exit 1
fi

echo "prek installed successfully"
