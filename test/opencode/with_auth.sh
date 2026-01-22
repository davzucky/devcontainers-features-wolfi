#!/bin/bash

set -e

source dev-container-features-test-lib

TARGET_HOME="${HOME}"
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="${_REMOTE_USER_HOME}"
fi
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME=$(grep -E "^${_REMOTE_USER}:" /etc/passwd | cut -d: -f6)
fi
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="/root"
fi

TARGET_AUTH="${TARGET_HOME}/.local/share/opencode/auth.json"
STAGED_AUTH="$(pwd)/.opencode-auth.json"

check "auth copy hook installed" test -f /usr/local/share/opencode-auth-copy.sh
check "auth copy flag installed" test -f /usr/local/share/opencode-copyauth.flag
check "auth copied" test -f "${TARGET_AUTH}"
check "staged auth removed" test ! -f "${STAGED_AUTH}"

reportResults
