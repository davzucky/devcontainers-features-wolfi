#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_CONFIG=${COPYCONFIG:-"false"}
USE_GIT_AUTH=${USEGITAUTH:-"false"}

echo "Installing glab..."

apk update
if [ "${VERSION}" = "latest" ]; then
    apk add --no-cache glab
else
    apk add --no-cache "glab=${VERSION}"
fi

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

if [ -z "${TARGET_USER}" ] || [ -z "${TARGET_HOME}" ] || [ "${TARGET_HOME}" = "/root" ]; then
    FALLBACK_USER=$(awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}' /etc/passwd)
    if [ -n "${FALLBACK_USER}" ] && id -u "${FALLBACK_USER}" >/dev/null 2>&1; then
        TARGET_USER="${FALLBACK_USER}"
        TARGET_HOME=$(awk -F: -v user="${TARGET_USER}" '$1==user{print $6}' /etc/passwd)
    fi
fi

if [ -z "${TARGET_USER}" ] && [ -n "${TARGET_HOME}" ]; then
    TARGET_USER=$(awk -F: -v home="${TARGET_HOME}" '$6==home{print $1; exit}' /etc/passwd)
fi

TARGET_CONFIG="${TARGET_HOME}/.config/glab-cli/config.yml"

if [ -f "${FLAG_FILE}" ] && [ -f "${SOURCE_CONFIG}" ]; then
    TARGET_DIR=$(dirname "${TARGET_CONFIG}")
    mkdir -p "${TARGET_DIR}"
    cp "${SOURCE_CONFIG}" "${TARGET_CONFIG}"

    if [ -n "${TARGET_USER}" ] && id -u "${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=$(id -gn "${TARGET_USER}" 2>/dev/null || true)
        if [ -n "${TARGET_GROUP}" ]; then
            chown "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_DIR}" "${TARGET_CONFIG}"
        else
            chown "${TARGET_USER}" "${TARGET_DIR}" "${TARGET_CONFIG}"
        fi
    fi

    chmod 700 "${TARGET_DIR}"
    chmod 600 "${TARGET_CONFIG}"
fi

if [ -f "${AUTH_FLAG_FILE}" ]; then
    if command -v git >/dev/null 2>&1; then
        WORKSPACE_DIR="${WORKSPACE_FOLDER:-}"
        if [ -z "${WORKSPACE_DIR}" ]; then
            CURRENT_DIR=$(pwd)
            if git -C "${CURRENT_DIR}" rev-parse --show-toplevel >/dev/null 2>&1; then
                WORKSPACE_DIR=$(git -C "${CURRENT_DIR}" rev-parse --show-toplevel)
            fi
        fi
        if [ -z "${WORKSPACE_DIR}" ] && [ -d "/workspaces" ]; then
            for candidate in /workspaces/*; do
                if [ -d "${candidate}" ] && git -C "${candidate}" rev-parse --show-toplevel >/dev/null 2>&1; then
                    WORKSPACE_DIR=$(git -C "${candidate}" rev-parse --show-toplevel)
                    break
                fi
            done
        fi

        if [ -z "${WORKSPACE_DIR}" ]; then
            echo "Workspace not found; skipping glab git auth configuration"
        else
            REMOTE_URL=$(git -C "${WORKSPACE_DIR}" remote get-url origin 2>/dev/null || true)
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
        fi
    else
        echo "git not found; skipping glab git auth configuration"
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
