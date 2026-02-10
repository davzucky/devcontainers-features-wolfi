#!/bin/bash

set -e

source dev-container-features-test-lib

check "opencode installed" opencode --version
check "auth copy flag missing" test ! -f /usr/local/share/opencode-copyauth.flag

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

TARGET_PROFILE_DIR="${TARGET_HOME}/.local/share/opencode"
check "profile symlink missing" test ! -L "${TARGET_PROFILE_DIR}"

reportResults
