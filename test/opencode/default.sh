#!/bin/bash

set -e

source dev-container-features-test-lib

check "opencode installed" opencode --version
check "ripgrep installed" rg --version
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

if [ "${TARGET_HOME}" = "/root" ]; then
    FALLBACK_USER=$(awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}' /etc/passwd)
    if [ -n "${FALLBACK_USER}" ]; then
        FALLBACK_HOME=$(awk -F: -v user="${FALLBACK_USER}" '$1==user{print $6}' /etc/passwd)
        if [ -n "${FALLBACK_HOME}" ]; then
            TARGET_HOME="${FALLBACK_HOME}"
        fi
    fi
fi

TARGET_AUTH="${TARGET_HOME}/.local/share/opencode/auth.json"
check "auth file missing" test ! -f "${TARGET_AUTH}"

reportResults
