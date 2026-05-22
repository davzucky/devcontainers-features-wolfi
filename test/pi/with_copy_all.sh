#!/bin/bash
set -e

source dev-container-features-test-lib

HOOK_TARGET_HOME=$(awk -F= '$1=="TARGET_HOME" {gsub(/"/, "", $2); print $2; exit}' /usr/local/share/pi-agent-copy.sh)
if [ -z "${HOOK_TARGET_HOME}" ]; then
    HOOK_TARGET_HOME="/root"
fi

TARGET_AGENT="${PI_CODING_AGENT_DIR:-${HOOK_TARGET_HOME}/.pi/agent}"

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
