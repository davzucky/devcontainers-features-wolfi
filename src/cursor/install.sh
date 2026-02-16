#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_AUTH=${COPYAUTH:-"false"}

# Checks if packages are installed and installs them if not
install_if_not() {
    if [ -z "$(apk list -I "$@")" ]; then
        echo "Install package $@"
        apk add --no-cache "$@"
    fi
}

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
install_if_not ca-certificates
install_if_not curl
install_if_not libgcc
install_if_not libstdc++

INSTALL_DIR="/usr/local/lib/cursor-agent"
VERSION_FILE="${INSTALL_DIR}/VERSION"

if [ -f "${VERSION_FILE}" ]; then
    INSTALLED_VERSION=$(cat "${VERSION_FILE}")
    if [ "${INSTALLED_VERSION}" = "${VERSION_TAG}" ] \
        && [ -x "${INSTALL_DIR}/cursor-agent" ] \
        && [ -x "/usr/local/bin/agent" ] \
        && [ -x "/usr/local/bin/cursor-agent" ]; then
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
ln -sf "${INSTALL_DIR}/cursor-agent" /usr/local/bin/cursor-agent

if ! command -v agent >/dev/null 2>&1; then
    echo "Cursor Agent installation failed"
    exit 1
fi

echo "Cursor Agent installed successfully"

echo "Installing Cursor auth copy hook"
mkdir -p /usr/local/share

RESOLVED_TARGET_USER="${_REMOTE_USER:-}"
RESOLVED_TARGET_HOME=""

if [ -n "${_REMOTE_USER_HOME:-}" ]; then
    RESOLVED_TARGET_HOME="${_REMOTE_USER_HOME}"
elif [ -n "${RESOLVED_TARGET_USER}" ] && id -u "${RESOLVED_TARGET_USER}" >/dev/null 2>&1; then
    RESOLVED_TARGET_HOME=$(awk -F: -v user="${RESOLVED_TARGET_USER}" '$1==user{print $6}' /etc/passwd)
fi

if [ -z "${RESOLVED_TARGET_HOME}" ]; then
    RESOLVED_TARGET_HOME="${HOME}"
fi

if [ -z "${RESOLVED_TARGET_USER}" ] || [ -z "${RESOLVED_TARGET_HOME}" ] || [ "${RESOLVED_TARGET_HOME}" = "/root" ]; then
    FALLBACK_USER=$(awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}' /etc/passwd)
    if [ -n "${FALLBACK_USER}" ] && id -u "${FALLBACK_USER}" >/dev/null 2>&1; then
        RESOLVED_TARGET_USER="${FALLBACK_USER}"
        RESOLVED_TARGET_HOME=$(awk -F: -v user="${RESOLVED_TARGET_USER}" '$1==user{print $6}' /etc/passwd)
    fi
fi

if [ -z "${RESOLVED_TARGET_USER}" ] && [ -n "${RESOLVED_TARGET_HOME}" ]; then
    RESOLVED_TARGET_USER=$(awk -F: -v home="${RESOLVED_TARGET_HOME}" '$6==home{print $1; exit}' /etc/passwd)
fi

if [ -z "${RESOLVED_TARGET_HOME}" ]; then
    RESOLVED_TARGET_HOME="/root"
fi

cat << EOF > /usr/local/share/cursor-auth-copy.sh
#!/bin/sh
set -e

SOURCE_AUTH="/tmp/cursor-host-tmp/auth.json"
FLAG_FILE="/usr/local/share/cursor-copyauth.flag"
TARGET_USER="${RESOLVED_TARGET_USER}"
TARGET_HOME="${RESOLVED_TARGET_HOME}"

TARGET_AUTH="\${TARGET_HOME}/.config/cursor/auth.json"

if [ -f "\${FLAG_FILE}" ] && [ -f "\${SOURCE_AUTH}" ]; then
    TARGET_DIR=\$(dirname "\${TARGET_AUTH}")
    mkdir -p "\${TARGET_DIR}"
    cp "\${SOURCE_AUTH}" "\${TARGET_AUTH}"

    if [ -n "\${TARGET_USER}" ] && id -u "\${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=\$(id -gn "\${TARGET_USER}" 2>/dev/null || true)
        if [ -n "\${TARGET_GROUP}" ]; then
            chown "\${TARGET_USER}:\${TARGET_GROUP}" "\${TARGET_DIR}" "\${TARGET_AUTH}"
        else
            chown "\${TARGET_USER}" "\${TARGET_DIR}" "\${TARGET_AUTH}"
        fi
    fi

    chmod 700 "\${TARGET_DIR}"
    chmod 600 "\${TARGET_AUTH}"
fi

EOF

chmod +x /usr/local/share/cursor-auth-copy.sh

if [ "${COPY_AUTH}" = "true" ]; then
    echo "Enabling Cursor auth copy"
    : > /usr/local/share/cursor-copyauth.flag
else
    rm -f /usr/local/share/cursor-copyauth.flag
fi
