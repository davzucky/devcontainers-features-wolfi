#!/bin/bash

set -e

source dev-container-features-test-lib

check "mise on PATH" mise --version

check "opencode installed" opencode --version
check "Node not installed" sh -c '! command -v node'
check "ripgrep installed" rg --version
check "auth copy flag missing" test ! -f /usr/local/share/opencode-copyauth.flag
check "config copy flag missing" test ! -f /usr/local/share/opencode-copyconfig.flag

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

TARGET_AUTH="${TARGET_HOME}/.local/share/opencode/auth.json"
TARGET_CONFIG="${TARGET_HOME}/.config/opencode/opencode.json"
check "auth file missing" test ! -f "${TARGET_AUTH}"
check "config file missing" test ! -f "${TARGET_CONFIG}"

SYSTEM_VERSION=$(opencode --version)
adduser -D opencode-test
check "project version installs without Node" su opencode-test -s /bin/sh -c '
    set -e
    cd "$HOME"
    mkdir project
    cd project
    printf "[tools]\nopencode = \"2.2.4\"\n" > mise.toml
    mise trust
    mise install opencode
    [ "$(opencode --version)" = "opencode v2.2.4" ]
    case "$(mise which opencode)" in "$HOME"/*) ;; *) exit 1 ;; esac
    ! command -v node
'
check "system default unchanged" test "$(opencode --version)" = "${SYSTEM_VERSION}"

reportResults
