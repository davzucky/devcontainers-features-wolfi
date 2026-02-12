#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}

echo "Installing chromium..."

apk update
if [ "${VERSION}" = "latest" ]; then
    apk add --no-cache chromium
else
    apk add --no-cache "chromium=${VERSION}"
fi

if ! command -v chromium >/dev/null 2>&1; then
    echo "chromium installation failed"
    exit 1
fi

echo "chromium installed successfully"
