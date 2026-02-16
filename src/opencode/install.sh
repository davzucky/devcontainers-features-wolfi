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

if ! command -v rg >/dev/null 2>&1; then
    echo "Installing ripgrep"
    apk add --no-cache ripgrep
fi

OPENCODE_INSTALLED="false"
if command -v opencode >/dev/null 2>&1; then
    if [ "${VERSION}" = "latest" ]; then
        echo "opencode already installed, skipping"
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

echo "Installing opencode auth copy hook"
mkdir -p /usr/local/share

cat << 'EOF' > /usr/local/share/opencode-auth-copy.sh
#!/bin/sh
set -e

SOURCE_AUTH="/tmp/opencode-host-tmp/auth.json"
FLAG_FILE="/usr/local/share/opencode-copyauth.flag"
TARGET_USER="${_REMOTE_USER:-}"
TARGET_HOME=""

if [ -n "${_REMOTE_USER_HOME:-}" ]; then
    TARGET_HOME="${_REMOTE_USER_HOME}"
elif [ -n "${TARGET_USER}" ] && id -u "${TARGET_USER}" >/dev/null 2>&1; then
    TARGET_HOME=$(awk -F: -v user="${TARGET_USER}" '$1==user{print $6}' /etc/passwd)
fi

if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="${HOME}"
fi

if [ -z "${TARGET_USER}" ] && [ -n "${TARGET_HOME}" ]; then
    TARGET_USER=$(awk -F: -v home="${TARGET_HOME}" '$6==home{print $1; exit}' /etc/passwd)
fi

TARGET_AUTH="${TARGET_HOME}/.local/share/opencode/auth.json"

if [ -f "${FLAG_FILE}" ] && [ -f "${SOURCE_AUTH}" ]; then
    TARGET_DIR=$(dirname "${TARGET_AUTH}")
    mkdir -p "${TARGET_DIR}"
    cp "${SOURCE_AUTH}" "${TARGET_AUTH}"

    if [ -n "${TARGET_USER}" ] && id -u "${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=$(id -gn "${TARGET_USER}" 2>/dev/null || true)
        if [ -n "${TARGET_GROUP}" ]; then
            chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_DIR}" "${TARGET_AUTH}"
        else
            chown "${TARGET_USER}" "${TARGET_DIR}" "${TARGET_AUTH}"
        fi
    fi

    chmod 700 "${TARGET_DIR}"
    chmod 600 "${TARGET_AUTH}"
fi

EOF

chmod +x /usr/local/share/opencode-auth-copy.sh

if [ "${COPY_AUTH}" = "true" ]; then
    echo "Enabling opencode auth copy"
    : > /usr/local/share/opencode-copyauth.flag
fi

echo "opencode installed successfully"
