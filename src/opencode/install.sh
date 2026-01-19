#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_AUTH=${COPYAUTH:-"false"}

ARCH=$(uname -m)
ARCHIVE_NAME=""

case "${ARCH}" in
    x86_64)
        ARCHIVE_NAME="opencode-linux-x64.tar.gz"
        ;;
    aarch64|arm64)
        ARCHIVE_NAME="opencode-linux-arm64.tar.gz"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

apk update
apk add --no-cache ca-certificates curl libarchive-tools

OPENCODE_INSTALLED="false"
if command -v opencode >/dev/null 2>&1; then
    echo "opencode already installed, running upgrade"
    opencode upgrade
    echo "opencode upgrade complete"
    OPENCODE_INSTALLED="true"
fi

if [ "${OPENCODE_INSTALLED}" = "false" ]; then
    if [ "${VERSION}" = "latest" ]; then
        REDIRECT_URL=$(curl -sI https://github.com/anomalyco/opencode/releases/latest | awk 'tolower($1) == "location:" {print $2}' | tr -d '\r')
        if [ -z "${REDIRECT_URL}" ]; then
            echo "Failed to resolve latest opencode release"
            exit 1
        fi
        VERSION_TAG=${REDIRECT_URL##*/}
    else
        case "${VERSION}" in
            v*)
                VERSION_TAG="${VERSION}"
                ;;
            *)
                VERSION_TAG="v${VERSION}"
                ;;
        esac
    fi

    DOWNLOAD_URL="https://github.com/anomalyco/opencode/releases/download/${VERSION_TAG}/${ARCHIVE_NAME}"
    WORKDIR=$(mktemp -d)

    if ! curl -sSL "${DOWNLOAD_URL}" -o "${WORKDIR}/${ARCHIVE_NAME}"; then
        echo "Failed to download opencode from ${DOWNLOAD_URL}"
        exit 1
    fi

    bsdtar -xzf "${WORKDIR}/${ARCHIVE_NAME}" -C "${WORKDIR}"
    if [ ! -f "${WORKDIR}/opencode" ]; then
        echo "opencode binary not found in archive"
        exit 1
    fi

    install -m 0755 "${WORKDIR}/opencode" /usr/bin/opencode
fi

if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode installation failed"
    exit 1
fi

if [ "${COPY_AUTH}" = "true" ]; then
    if [ -z "${_REMOTE_USER}" ] || [ "${_REMOTE_USER}" = "root" ] || [ "${_REMOTE_USER}" = "0" ]; then
        TARGET_USER="root"
    else
        TARGET_USER="${_REMOTE_USER}"
    fi

    TARGET_HOME="/root"
    if [ -n "${_REMOTE_USER_HOME}" ]; then
        TARGET_HOME="${_REMOTE_USER_HOME}"
    else
        TARGET_HOME_TMP=$(grep -E "^${TARGET_USER}:" /etc/passwd | cut -d: -f6)
        if [ -n "${TARGET_HOME_TMP}" ]; then
            TARGET_HOME="${TARGET_HOME_TMP}"
        fi
    fi

    SOURCE_AUTH="${HOME}/.local/share/opencode/auth.json"
    TARGET_DIR="${TARGET_HOME}/.local/share/opencode"
    TARGET_AUTH="${TARGET_DIR}/auth.json"

    if [ -f "${SOURCE_AUTH}" ]; then
        mkdir -p "${TARGET_DIR}"
        cp "${SOURCE_AUTH}" "${TARGET_AUTH}"
        chown "${TARGET_USER}":"${TARGET_USER}" "${TARGET_AUTH}"
        echo "Copied opencode auth.json to ${TARGET_AUTH}"
    else
        echo "opencode auth.json not found at ${SOURCE_AUTH}, skipping copy"
    fi
fi

echo "opencode installed successfully"
