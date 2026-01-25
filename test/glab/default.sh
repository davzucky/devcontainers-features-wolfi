#!/bin/bash

set -e

source dev-container-features-test-lib

check "glab installed" glab --version
check "config copy flag missing" test ! -f /usr/local/share/glab-copyconfig.flag

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

TARGET_CONFIG="${TARGET_HOME}/.config/glab-cli/config.yml"
check "config file missing" test ! -f "${TARGET_CONFIG}"

reportResults
