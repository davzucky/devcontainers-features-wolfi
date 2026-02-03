#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}

ARCH=$(uname -m)
ARCH_SUFFIX=""

case "${ARCH}" in
    x86_64|amd64)
        ARCH_SUFFIX="x64"
        ;;
    aarch64|arm64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

VERSION_TAG="2026.01.28-fd13201"
if [ "${VERSION}" != "latest" ]; then
    VERSION_TAG="${VERSION}"
fi

apk update
apk add --no-cache ca-certificates curl libgcc libstdc++

INSTALL_DIR="/usr/local/lib/cursor-agent"
VERSION_FILE="${INSTALL_DIR}/VERSION"

if [ -f "${VERSION_FILE}" ]; then
    INSTALLED_VERSION=$(cat "${VERSION_FILE}")
    if [ "${INSTALLED_VERSION}" = "${VERSION_TAG}" ]; then
        echo "Cursor Agent already installed (${INSTALLED_VERSION}), skipping"
        exit 0
    fi
fi

DOWNLOAD_URL="https://downloads.cursor.com/lab/${VERSION_TAG}/linux/${ARCH_SUFFIX}/agent-cli-package.tar.gz"

WORKDIR=$(mktemp -d)
trap "rm -rf '${WORKDIR}'" EXIT

echo "Downloading Cursor Agent from ${DOWNLOAD_URL}"
if ! curl -fSL "${DOWNLOAD_URL}" -o "${WORKDIR}/agent-cli-package.tar.gz"; then
    echo "Failed to download Cursor Agent package"
    exit 1
fi

mkdir -p "${WORKDIR}/extract"
if ! tar --strip-components=1 -xzf "${WORKDIR}/agent-cli-package.tar.gz" -C "${WORKDIR}/extract"; then
    echo "Failed to extract Cursor Agent package"
    exit 1
fi

if [ ! -f "${WORKDIR}/extract/cursor-agent" ]; then
    echo "Cursor Agent binary not found in archive"
    exit 1
fi

rm -rf "${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}"
cp -R "${WORKDIR}/extract"/. "${INSTALL_DIR}/"
printf "%s" "${VERSION_TAG}" > "${VERSION_FILE}"

mkdir -p /usr/local/bin
ln -sf "${INSTALL_DIR}/cursor-agent" /usr/local/bin/agent

if ! command -v agent >/dev/null 2>&1; then
    echo "Cursor Agent installation failed"
    exit 1
fi

echo "Cursor Agent installed successfully"
