#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_AUTH=${COPYAUTH:-"false"}
COPY_CONFIG=${COPYCONFIG:-"false"}

apk update
apk add --no-cache ca-certificates libgcc libstdc++ ripgrep

mise install --system "opencode@${VERSION#v}"
mise use --pin --path /etc/mise/conf.d/opencode.toml "opencode@${VERSION#v}"
mise reshim --system
export PATH="/usr/local/share/mise/shims:${PATH}"
command -v opencode
opencode --version

echo "Installing opencode config copy hook"
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

cat <<EOF > /usr/local/share/opencode-auth-copy.sh
#!/bin/sh
set -e

SOURCE_AUTH="/tmp/opencode-host-tmp/auth.json"
SOURCE_CONFIG="/tmp/opencode-host-tmp/opencode.json"
FLAG_FILE="/usr/local/share/opencode-copyauth.flag"
CONFIG_FLAG_FILE="/usr/local/share/opencode-copyconfig.flag"
TARGET_USER="${RESOLVED_TARGET_USER}"
TARGET_HOME="${RESOLVED_TARGET_HOME}"

TARGET_AUTH="\${TARGET_HOME}/.local/share/opencode/auth.json"
TARGET_CONFIG="\${TARGET_HOME}/.config/opencode/opencode.json"

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

if [ -f "\${CONFIG_FLAG_FILE}" ] && [ -f "\${SOURCE_CONFIG}" ]; then
    TARGET_DIR=\$(dirname "\${TARGET_CONFIG}")
    mkdir -p "\${TARGET_DIR}"
    cp "\${SOURCE_CONFIG}" "\${TARGET_CONFIG}"

    if [ -n "\${TARGET_USER}" ] && id -u "\${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=\$(id -gn "\${TARGET_USER}" 2>/dev/null || true)
        if [ -n "\${TARGET_GROUP}" ]; then
            chown "\${TARGET_USER}:\${TARGET_GROUP}" "\${TARGET_DIR}" "\${TARGET_CONFIG}"
        else
            chown "\${TARGET_USER}" "\${TARGET_DIR}" "\${TARGET_CONFIG}"
        fi
    fi

    chmod 700 "\${TARGET_DIR}"
    chmod 600 "\${TARGET_CONFIG}"
fi

EOF

chmod +x /usr/local/share/opencode-auth-copy.sh

if [ "${COPY_AUTH}" = "true" ]; then
    echo "Enabling opencode auth copy"
    : > /usr/local/share/opencode-copyauth.flag
else
    rm -f /usr/local/share/opencode-copyauth.flag
fi

if [ "${COPY_CONFIG}" = "true" ]; then
    echo "Enabling opencode config copy"
    : > /usr/local/share/opencode-copyconfig.flag
else
    rm -f /usr/local/share/opencode-copyconfig.flag
fi

echo "opencode installed successfully"
