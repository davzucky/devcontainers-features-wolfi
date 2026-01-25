#!/bin/sh
set -e

COPY_CONFIG=${COPYCONFIG:-"false"}
USE_GIT_AUTH=${USEGITAUTH:-"false"}

echo "Installing glab..."

apk update
apk add --no-cache glab

if [ "${USE_GIT_AUTH}" = "true" ]; then
    apk add --no-cache git
fi

if ! command -v glab >/dev/null 2>&1; then
    echo "glab installation failed"
    exit 1
fi

echo "Installing glab config copy hook"
mkdir -p /usr/local/share

cat << 'EOF' > /usr/local/share/glab-config-copy.sh
#!/bin/sh
set -e

SOURCE_CONFIG="/tmp/glab-host-tmp/config.yml"
FLAG_FILE="/usr/local/share/glab-copyconfig.flag"
AUTH_FLAG_FILE="/usr/local/share/glab-git-auth.flag"
TARGET_CONFIG="${HOME}/.config/glab-cli/config.yml"

if [ -f "${FLAG_FILE}" ] && [ -f "${SOURCE_CONFIG}" ]; then
    mkdir -p "$(dirname "${TARGET_CONFIG}")"
    cp "${SOURCE_CONFIG}" "${TARGET_CONFIG}"
    chmod 600 "${TARGET_CONFIG}"
fi

if [ -f "${AUTH_FLAG_FILE}" ]; then
    if [ -z "${WORKSPACE_FOLDER:-}" ]; then
        echo "WORKSPACE_FOLDER not set; skipping glab git auth configuration"
    else
        if command -v git >/dev/null 2>&1; then
            REMOTE_URL=$(git -C "${WORKSPACE_FOLDER}" remote get-url origin 2>/dev/null || true)
            if [ -z "${REMOTE_URL}" ]; then
                echo "No origin remote found; skipping glab git auth configuration"
            else
                case "${REMOTE_URL}" in
                    git@*|ssh://*)
                        echo "SSH remote detected (${REMOTE_URL}); skipping glab git auth configuration"
                        ;;
                    *)
                        git config --global "credential.${REMOTE_URL}.helper" "!glab auth git-credential"
                        echo "Configured glab git auth for ${REMOTE_URL}"
                        ;;
                esac
            fi
        else
            echo "git not found; skipping glab git auth configuration"
        fi
    fi
fi

EOF

chmod +x /usr/local/share/glab-config-copy.sh

if [ "${COPY_CONFIG}" = "true" ]; then
    echo "Enabling glab config copy"
    : > /usr/local/share/glab-copyconfig.flag
fi

if [ "${USE_GIT_AUTH}" = "true" ]; then
    echo "Enabling glab git auth"
    : > /usr/local/share/glab-git-auth.flag
fi

echo "glab installed successfully"
