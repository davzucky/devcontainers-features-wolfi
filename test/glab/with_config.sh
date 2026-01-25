#!/bin/bash

set -e

source dev-container-features-test-lib

TARGET_HOME="${HOME}"
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="${_REMOTE_USER_HOME}"
fi
if [ -z "${TARGET_HOME}" ]; then
    if [ -n "${_REMOTE_USER:-}" ]; then
        TARGET_HOME=$(grep -E "^${_REMOTE_USER}:" /etc/passwd | cut -d: -f6)
    fi
fi
if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="/root"
fi

TARGET_CONFIG="${TARGET_HOME}/.config/glab-cli/config.yml"
SOURCE_CONFIG="/tmp/glab-host-tmp/config.yml"

check "config copy hook installed" test -f /usr/local/share/glab-config-copy.sh
check "config copy flag installed" test -f /usr/local/share/glab-copyconfig.flag

if [ -f "${SOURCE_CONFIG}" ]; then
    check "config copied" test -f "${TARGET_CONFIG}"
else
    check "config missing on host" test ! -f "${TARGET_CONFIG}"
fi

reportResults
