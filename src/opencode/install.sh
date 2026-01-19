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
    if [ "${VERSION}" = "latest" ]; then
        echo "opencode already installed, running upgrade"
        opencode upgrade
        echo "opencode upgrade complete"
        OPENCODE_INSTALLED="true"
    else
        CURRENT_VERSION=$(opencode --version 2>/dev/null | awk '{print $NF}')
        if [ "${CURRENT_VERSION}" = "${VERSION}" ] || [ "${CURRENT_VERSION}" = "v${VERSION}" ]; then
            echo "opencode already installed (${CURRENT_VERSION}), skipping"
            OPENCODE_INSTALLED="true"
        fi
    fi
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
    trap "rm -rf '${WORKDIR}'" EXIT

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
    echo "Installing opencode auth copy hook"
    mkdir -p /usr/local/share /etc/profile.d

    cat << 'EOF' > /usr/local/share/opencode-auth-copy.sh
#!/bin/sh
set -e

SOURCE_AUTH="/tmp/opencode-host-home/.local/share/opencode/auth.json"

TARGET_USER="${_REMOTE_USER:-root}"
if [ "${TARGET_USER}" = "0" ] || [ "${TARGET_USER}" = "root" ]; then
    TARGET_USER="root"
fi

TARGET_HOME="${_REMOTE_USER_HOME}"
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME=$(grep -E "^${TARGET_USER}:" /etc/passwd | cut -d: -f6)
fi
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="/root"
fi

TARGET_AUTH="${TARGET_HOME}/.local/share/opencode/auth.json"

    if [ -f "${SOURCE_AUTH}" ] && [ ! -f "${TARGET_AUTH}" ]; then
        mkdir -p "$(dirname "${TARGET_AUTH}")"
        cp "${SOURCE_AUTH}" "${TARGET_AUTH}"
        chmod 600 "${TARGET_AUTH}"
        if [ "$(id -u)" = "0" ]; then
            TARGET_GID=$(id -g "${TARGET_USER}" 2>/dev/null || echo "0")
            chown "${TARGET_USER}":"${TARGET_GID}" "${TARGET_AUTH}"
        fi
    fi

EOF

    chmod +x /usr/local/share/opencode-auth-copy.sh
    ln -sf /usr/local/share/opencode-auth-copy.sh /etc/profile.d/opencode-auth-copy.sh
fi

echo "opencode installed successfully"
