#!/bin/bash
set -e

source dev-container-features-test-lib

HOOK_TARGET_HOME=$(awk -F= '$1=="TARGET_HOME" {gsub(/"/, "", $2); print $2; exit}' /usr/local/share/agent-skills-copy.sh)
if [ -z "${HOOK_TARGET_HOME}" ]; then
    HOOK_TARGET_HOME="/root"
fi

TARGET_SKILLS="${HOOK_TARGET_HOME}/.agents/skills"

check "copy hook installed" test -x /usr/local/share/agent-skills-copy.sh
check "nested skill copied" test -f "${TARGET_SKILLS}/test-skill/SKILL.md"
check "nested skill content copied" grep -q "name: test-skill" "${TARGET_SKILLS}/test-skill/SKILL.md"
check "helper copied" test -f "${TARGET_SKILLS}/test-skill/bin/helper.sh"
check "helper executable bit preserved" test -x "${TARGET_SKILLS}/test-skill/bin/helper.sh"
check "stale skill removed" test ! -e "${TARGET_SKILLS}/stale-skill/SKILL.md"

reportResults
