#!/bin/bash

set -e

source dev-container-features-test-lib

check "claude installed" claude --version
check "settings copy flag missing" test ! -f /usr/local/share/claude-copysettings.flag

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
check "settings file missing" test ! -f "${TARGET_SETTINGS}"

reportResults
