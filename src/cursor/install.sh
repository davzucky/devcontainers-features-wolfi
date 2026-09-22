#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_AUTH=${COPYAUTH:-"false"}

apk update
apk add --no-cache ca-certificates bash libgcc libstdc++

# Expose only Cursor commands, keeping its bundled Node off PATH.
# A backend alias also applies these options to project-selected versions.
cat > /etc/mise/conf.d/cursor.toml <<'EOF'
[tool_alias]
cursor-agent = '''http:cursor-agent[bin_path=bin,postinstall='mkdir -p "$MISE_TOOL_INSTALL_PATH/bin" && ln -sf ../dist-package/cursor-agent "$MISE_TOOL_INSTALL_PATH/bin/cursor-agent" && ln -sf ../dist-package/cursor-agent "$MISE_TOOL_INSTALL_PATH/bin/agent"']'''
EOF

RESOLVED_VERSION=${VERSION#v}
if [ "${RESOLVED_VERSION}" = "latest" ]; then
    RESOLVED_VERSION=$(mise latest cursor-agent)
fi
case "${RESOLVED_VERSION}" in
    ''|*[!a-zA-Z0-9.+-]*)
        echo "Unsupported cursor-agent version: ${VERSION}"
        exit 1
        ;;
esac
printf '\n[tools]\ncursor-agent = "%s"\n' "${RESOLVED_VERSION}" >> /etc/mise/conf.d/cursor.toml
mise install --system cursor-agent
mise reshim --system
export PATH="/usr/local/share/mise/shims:${PATH}"
command -v cursor-agent
cursor-agent --version

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
