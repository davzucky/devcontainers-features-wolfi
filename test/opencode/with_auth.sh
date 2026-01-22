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
SOURCE_AUTH="/tmp/opencode-host-home/auth.json"

check "auth copy hook installed" test -f /usr/local/share/opencode-auth-copy.sh
check "auth copy flag installed" test -f /usr/local/share/opencode-copyauth.flag

if [ -f "${SOURCE_AUTH}" ]; then
    check "auth copied" test -f "${TARGET_AUTH}"
else
    check "auth missing on host" test ! -f "${TARGET_AUTH}"
fi

reportResults
