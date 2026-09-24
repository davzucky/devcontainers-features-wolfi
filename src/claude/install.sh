#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_SETTINGS=${COPYSETTINGS:-"false"}

apk update
apk add --no-cache ca-certificates curl libgcc libstdc++ ripgrep

if [ "${VERSION}" = "stable" ]; then
    VERSION=$(curl -fsSL https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/stable)
    if [ -z "${VERSION}" ]; then
        echo "Failed to resolve stable Claude Code version"
        exit 1
    fi
fi

# The HTTP backend verifies upstream manifest checksums for older releases too.
cat > /etc/mise/conf.d/claude.toml <<'EOF'
[tool_alias]
claude = "http:claude"
EOF
RESOLVED_VERSION=${VERSION#v}
if [ "${RESOLVED_VERSION}" = "latest" ]; then
    RESOLVED_VERSION=$(mise latest claude)
fi
case "${RESOLVED_VERSION}" in
    ''|*[!a-zA-Z0-9.+-]*)
        echo "Unsupported Claude Code version: ${VERSION}"
        exit 1
        ;;
esac
printf '\n[tools]\nclaude = "%s"\n' "${RESOLVED_VERSION}" >> /etc/mise/conf.d/claude.toml
mise install --system claude
mise reshim --system
export PATH="/usr/local/share/mise/shims:${PATH}"
command -v claude
claude --version

echo "Installing Claude Code settings copy hook"
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

cat << EOF > /usr/local/share/claude-settings-copy.sh
#!/bin/sh
set -e

SOURCE_SETTINGS="/tmp/claude-host-tmp/settings.json"
FLAG_FILE="/usr/local/share/claude-copysettings.flag"
TARGET_USER="${RESOLVED_TARGET_USER}"
TARGET_HOME="${RESOLVED_TARGET_HOME}"

TARGET_DIR="\${CLAUDE_CONFIG_DIR:-\${TARGET_HOME}/.claude}"
TARGET_SETTINGS="\${TARGET_DIR}/settings.json"

if [ -f "\${FLAG_FILE}" ] && [ -f "\${SOURCE_SETTINGS}" ]; then
    mkdir -p "\${TARGET_DIR}"
    cp "\${SOURCE_SETTINGS}" "\${TARGET_SETTINGS}"

    if [ -n "\${TARGET_USER}" ] && id -u "\${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=\$(id -gn "\${TARGET_USER}" 2>/dev/null || true)
        if [ -n "\${TARGET_GROUP}" ]; then
            chown "\${TARGET_USER}:\${TARGET_GROUP}" "\${TARGET_DIR}" "\${TARGET_SETTINGS}"
        else
            chown "\${TARGET_USER}" "\${TARGET_DIR}" "\${TARGET_SETTINGS}"
        fi
    fi

    chmod 700 "\${TARGET_DIR}"
    chmod 600 "\${TARGET_SETTINGS}"
fi

EOF

chmod +x /usr/local/share/claude-settings-copy.sh

if [ "${COPY_SETTINGS}" = "true" ]; then
    echo "Enabling Claude Code settings copy"
    : > /usr/local/share/claude-copysettings.flag
else
    rm -f /usr/local/share/claude-copysettings.flag
fi

echo "Claude Code installed successfully"
