#!/bin/bash

set -e

source dev-container-features-test-lib

check "git auth flag installed" test -f /usr/local/share/glab-git-auth.flag

WORKSPACE_DIR="${WORKSPACE_FOLDER}"
if [ -z "${WORKSPACE_DIR}" ] && [ -d "/workspaces" ]; then
    for candidate in /workspaces/*; do
        if [ -d "${candidate}/.git" ]; then
            WORKSPACE_DIR="${candidate}"
            break
        fi
    done
fi
if [ -z "${WORKSPACE_DIR}" ]; then
    WORKSPACE_DIR=$(pwd)
fi

REMOTE_URL=$(git -C "${WORKSPACE_DIR}" remote get-url origin 2>/dev/null || true)
if [ -z "${REMOTE_URL}" ]; then
    echo "No origin remote found; skipping git auth assertions"
    reportResults
    exit 0
fi

case "${REMOTE_URL}" in
    git@*|ssh://*)
        HELPER=$(git config --global --get "credential.${REMOTE_URL}.helper" 2>/dev/null || true)
        check "ssh remote not configured" test -z "${HELPER}"
        ;;
    *)
        check "git auth configured" test "$(git config --global --get "credential.${REMOTE_URL}.helper")" = "!glab auth git-credential"
        ;;
esac

reportResults
