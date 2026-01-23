#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_SETTINGS=${COPYSETTINGS:-"false"}

ARCH=$(uname -m)
PLATFORM=""

case "${ARCH}" in
    x86_64|amd64)
        PLATFORM="linux-x64"
        ;;
    aarch64|arm64)
        PLATFORM="linux-arm64"
        ;;
    *)
        echo "Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

apk update
apk add --no-cache ca-certificates curl libgcc libstdc++ ripgrep

BASE_URL="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

VERSION_TARGET="${VERSION}"
case "${VERSION}" in
    latest|stable)
        VERSION_TARGET=$(curl -fsSL "${BASE_URL}/${VERSION}")
        if [ -z "${VERSION_TARGET}" ]; then
            echo "Failed to resolve ${VERSION} Claude Code version"
            exit 1
        fi
        ;;
    v*)
        VERSION_TARGET=${VERSION#v}
        ;;
esac

CLAUDE_INSTALLED="false"
if command -v claude >/dev/null 2>&1; then
    CURRENT_VERSION=$(claude --version 2>/dev/null | awk '{print $NF}')
    if [ "${VERSION}" != "latest" ] && [ "${VERSION}" != "stable" ] && [ "${CURRENT_VERSION}" = "${VERSION_TARGET}" ]; then
        echo "claude already installed (${CURRENT_VERSION}), skipping"
        CLAUDE_INSTALLED="true"
    fi
fi

if [ "${CLAUDE_INSTALLED}" = "false" ]; then
    MANIFEST_JSON=$(curl -fsSL "${BASE_URL}/${VERSION_TARGET}/manifest.json")
    if [ -z "${MANIFEST_JSON}" ]; then
        echo "Failed to download Claude Code manifest"
        exit 1
    fi

    CHECKSUM=$(printf "%s" "${MANIFEST_JSON}" | awk -v platform="\"${PLATFORM}\"" '
        $0 ~ platform {found=1}
        found && $0 ~ /"checksum"/ {
            gsub(/.*"checksum"[[:space:]]*:[[:space:]]*"/, "")
            gsub(/".*/, "")
            print
            exit
        }
    ')

    if [ -z "${CHECKSUM}" ]; then
        echo "Failed to locate checksum for ${PLATFORM}"
        exit 1
    fi

    WORKDIR=$(mktemp -d)
    trap "rm -rf '${WORKDIR}'" EXIT

    DOWNLOAD_URL="${BASE_URL}/${VERSION_TARGET}/${PLATFORM}/claude"
    if ! curl -fsSL "${DOWNLOAD_URL}" -o "${WORKDIR}/claude"; then
        echo "Failed to download Claude Code from ${DOWNLOAD_URL}"
        exit 1
    fi

    ACTUAL_CHECKSUM=$(sha256sum "${WORKDIR}/claude" | awk '{print $1}')
    if [ "${ACTUAL_CHECKSUM}" != "${CHECKSUM}" ]; then
        echo "Checksum verification failed"
        exit 1
    fi

    mkdir -p /usr/local/bin
    install -m 0755 "${WORKDIR}/claude" /usr/local/bin/claude
fi

if ! command -v claude >/dev/null 2>&1; then
    echo "claude installation failed"
    exit 1
fi

echo "Installing Claude Code settings copy hook"
mkdir -p /usr/local/share

cat << 'EOF' > /usr/local/share/claude-settings-copy.sh
#!/bin/sh
set -e

SOURCE_SETTINGS="/tmp/claude-host-tmp/settings.json"
FLAG_FILE="/usr/local/share/claude-copysettings.flag"
TARGET_DIR="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
TARGET_SETTINGS="${TARGET_DIR}/settings.json"

if [ -f "${FLAG_FILE}" ] && [ -f "${SOURCE_SETTINGS}" ]; then
    mkdir -p "${TARGET_DIR}"
    cp "${SOURCE_SETTINGS}" "${TARGET_SETTINGS}"
    chmod 600 "${TARGET_SETTINGS}"
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
