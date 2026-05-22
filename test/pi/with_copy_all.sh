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

TARGET_AGENT="${PI_CODING_AGENT_DIR:-${TARGET_HOME}/.pi/agent}"

check "pi command exists" command -v pi
check "pi version works" pi --version
check "copy hook installed" test -f /usr/local/share/pi-agent-copy.sh
check "copy all flag installed" test -f /usr/local/share/pi-copyall.flag
check "settings copied" test -f "${TARGET_AGENT}/settings.json"
check "auth copied" test -f "${TARGET_AGENT}/auth.json"
check "models copied" test -f "${TARGET_AGENT}/models.json"
check "keybindings copied" test -f "${TARGET_AGENT}/keybindings.json"
check "agents copied" test -f "${TARGET_AGENT}/AGENTS.md"
check "system copied" test -f "${TARGET_AGENT}/SYSTEM.md"
check "append system copied" test -f "${TARGET_AGENT}/APPEND_SYSTEM.md"
check "prompts copied" test -f "${TARGET_AGENT}/prompts/review.md"
check "skills copied" test -f "${TARGET_AGENT}/skills/test-skill/SKILL.md"
check "extensions copied" test -f "${TARGET_AGENT}/extensions/test.ts"
check "themes copied" test -f "${TARGET_AGENT}/themes/test.json"
check "npm packages not copied" test ! -e "${TARGET_AGENT}/npm"
check "git packages not copied" test ! -e "${TARGET_AGENT}/git"

reportResults
