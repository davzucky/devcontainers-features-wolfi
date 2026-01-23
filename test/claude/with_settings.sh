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

TARGET_DIR="${CLAUDE_CONFIG_DIR:-${TARGET_HOME}/.claude}"
TARGET_SETTINGS="${TARGET_DIR}/settings.json"
SOURCE_SETTINGS="/tmp/claude-host-tmp/settings.json"

check "settings copy hook installed" test -f /usr/local/share/claude-settings-copy.sh
check "settings copy flag installed" test -f /usr/local/share/claude-copysettings.flag

if [ -f "${SOURCE_SETTINGS}" ]; then
    check "settings copied" test -f "${TARGET_SETTINGS}"
else
    check "settings missing on host" test ! -f "${TARGET_SETTINGS}"
fi

reportResults
