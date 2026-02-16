#!/bin/bash

set -e

source dev-container-features-test-lib

TARGET_USER="${_REMOTE_USER:-}"
TARGET_HOME=""

if [ -n "${_REMOTE_USER_HOME:-}" ]; then
    TARGET_HOME="${_REMOTE_USER_HOME}"
elif [ -n "${TARGET_USER}" ]; then
    TARGET_HOME=$(awk -F: -v user="${TARGET_USER}" '$1==user{print $6}' /etc/passwd)
fi

if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="${HOME:-}"
fi

if [ -z "${TARGET_USER}" ] || [ -z "${TARGET_HOME}" ] || [ "${TARGET_HOME}" = "/root" ]; then
    FALLBACK_USER=$(awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}' /etc/passwd)
    if [ -n "${FALLBACK_USER}" ]; then
        TARGET_USER="${FALLBACK_USER}"
        FALLBACK_HOME=$(awk -F: -v user="${FALLBACK_USER}" '$1==user{print $6}' /etc/passwd)
        if [ -n "${FALLBACK_HOME}" ]; then
            TARGET_HOME="${FALLBACK_HOME}"
        fi
    fi
fi

if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="/root"
fi

TARGET_CONFIG="${TARGET_HOME}/.config/gh/hosts.yml"
SOURCE_CONFIG="/tmp/gh-host-tmp/hosts.yml"

check "config copy hook installed" test -f /usr/local/share/gh-config-copy.sh
check "config copy flag installed" test -f /usr/local/share/gh-copyconfig.flag

if [ -f "${SOURCE_CONFIG}" ]; then
    check "config copied" test -f "${TARGET_CONFIG}"
else
    check "config missing on host" test ! -f "${TARGET_CONFIG}"
fi

reportResults
