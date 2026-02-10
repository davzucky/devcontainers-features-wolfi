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

TARGET_PROFILE_DIR="${TARGET_HOME}/.local/share/opencode"
SOURCE_PROFILE_DIR="/tmp/opencode-host-tmp"

check "auth copy hook installed" test -f /usr/local/share/opencode-auth-copy.sh
check "auth copy flag installed" test -f /usr/local/share/opencode-copyauth.flag
check "profile symlink enabled" test -L "${TARGET_PROFILE_DIR}"
check "profile symlink target" test "$(readlink "${TARGET_PROFILE_DIR}")" = "${SOURCE_PROFILE_DIR}"

if [ -f "${SOURCE_PROFILE_DIR}/auth.json" ]; then
    check "auth visible" test -f "${TARGET_PROFILE_DIR}/auth.json"
else
    check "auth absent" test ! -f "${TARGET_PROFILE_DIR}/auth.json"
fi

reportResults
