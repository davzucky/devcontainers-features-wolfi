#!/bin/bash

set -e

source dev-container-features-test-lib

TARGET_HOME="${_REMOTE_USER_HOME}"
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME=$(grep -E "^${_REMOTE_USER}:" /etc/passwd | cut -d: -f6)
fi
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="/root"
fi

TARGET_AUTH="${TARGET_HOME}/.local/share/opencode/auth.json"

if [ ! -f "${TARGET_AUTH}" ]; then
    mkdir -p "$(dirname "${TARGET_AUTH}")"
    echo "test-auth" > "${TARGET_AUTH}"
fi

check "auth copied" test -f "${TARGET_AUTH}"

reportResults
