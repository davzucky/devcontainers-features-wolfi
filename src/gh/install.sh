#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
USE_GIT_AUTH=${USEGITAUTH:-"false"}
IMPORT_AUTH=${IMPORTAUTH:-"false"}

echo "Installing gh..."

apk update
if [ "${VERSION}" = "latest" ]; then
    apk add --no-cache gh
else
    apk add --no-cache "gh=${VERSION}"
fi

if [ "${USE_GIT_AUTH}" = "true" ]; then
    apk add --no-cache git
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "gh installation failed"
    exit 1
fi

echo "Installing gh post-start hook"
mkdir -p /usr/local/share

cat << EOF > /usr/local/share/gh-post-start.sh
#!/bin/sh

AUTH_FLAG_FILE="/usr/local/share/gh-git-auth.flag"
SOURCE_AUTH_EXPORT="/tmp/gh-host-tmp/auth-status.tsv"
IMPORT_AUTH_FLAG_FILE="/usr/local/share/gh-import-auth.flag"

if [ -f "\${AUTH_FLAG_FILE}" ]; then
    if command -v git >/dev/null 2>&1; then
        WORKSPACE_DIR="\${WORKSPACE_FOLDER:-}"
        if [ -z "\${WORKSPACE_DIR}" ]; then
            CURRENT_DIR=\$(pwd)
            if git -C "\${CURRENT_DIR}" rev-parse --show-toplevel >/dev/null 2>&1; then
                WORKSPACE_DIR=\$(git -C "\${CURRENT_DIR}" rev-parse --show-toplevel)
            fi
        fi
        if [ -z "\${WORKSPACE_DIR}" ] && [ -d "/workspaces" ]; then
            for candidate in /workspaces/*; do
                if [ -d "\${candidate}" ] && git -C "\${candidate}" rev-parse --show-toplevel >/dev/null 2>&1; then
                    WORKSPACE_DIR=\$(git -C "\${candidate}" rev-parse --show-toplevel)
                    break
                fi
            done
        fi

        if [ -z "\${WORKSPACE_DIR}" ]; then
            echo "Workspace not found; skipping gh git auth configuration"
        else
            REMOTE_URL=\$(git -C "\${WORKSPACE_DIR}" remote get-url origin 2>/dev/null || true)
            if [ -z "\${REMOTE_URL}" ]; then
                echo "No origin remote found; skipping gh git auth configuration"
            else
                case "\${REMOTE_URL}" in
                    git@*|ssh://*)
                        echo "SSH remote detected (\${REMOTE_URL}); skipping gh git auth configuration"
                        ;;
                    *)
                        git config --global "credential.\${REMOTE_URL}.helper" "!gh auth git-credential"
                        echo "Configured gh git auth for \${REMOTE_URL}"
                        ;;
                esac
            fi
        fi
    else
        echo "git not found; skipping gh git auth configuration"
    fi
fi

if [ -f "\${IMPORT_AUTH_FLAG_FILE}" ]; then
    if [ -f "\${SOURCE_AUTH_EXPORT}" ]; then
        if command -v gh >/dev/null 2>&1; then
            TAB_CHAR=\$(printf '\t')
            while IFS="\${TAB_CHAR}" read -r HOSTNAME TOKEN || [ -n "\${HOSTNAME}" ]; do
                if [ -z "\${HOSTNAME}" ] || [ -z "\${TOKEN}" ]; then
                    continue
                fi
                if printf '%s' "\${TOKEN}" | gh auth login --hostname "\${HOSTNAME}" --with-token >/dev/null 2>&1; then
                    echo "Imported gh auth for \${HOSTNAME}"
                else
                    echo "Failed to import gh auth for \${HOSTNAME}; continuing"
                fi
            done < "\${SOURCE_AUTH_EXPORT}"
        else
            echo "gh not found; skipping gh auth import"
        fi

        rm -f "\${SOURCE_AUTH_EXPORT}"
    else
        echo "No gh auth export file found; skipping gh auth import"
    fi
fi

EOF

chmod +x /usr/local/share/gh-post-start.sh

if [ "${USE_GIT_AUTH}" = "true" ]; then
    echo "Enabling gh git auth"
    : > /usr/local/share/gh-git-auth.flag
fi

if [ "${IMPORT_AUTH}" = "true" ]; then
    echo "Enabling gh auth import"
    : > /usr/local/share/gh-import-auth.flag
fi

echo "gh installed successfully"
