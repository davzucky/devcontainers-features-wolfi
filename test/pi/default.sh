#!/bin/bash
set -e

source dev-container-features-test-lib

check "pi command exists" command -v pi
check "pi version works" pi --version
check "copy hook installed" test -f /usr/local/share/pi-agent-copy.sh
check "copy all flag missing" test ! -f /usr/local/share/pi-copyall.flag
check "settings flag missing" test ! -f /usr/local/share/pi-copysettings.flag
check "auth flag missing" test ! -f /usr/local/share/pi-copyauth.flag
check "models flag missing" test ! -f /usr/local/share/pi-copymodels.flag
check "keybindings flag missing" test ! -f /usr/local/share/pi-copykeybindings.flag
check "instructions flag missing" test ! -f /usr/local/share/pi-copyinstructions.flag
check "prompts flag missing" test ! -f /usr/local/share/pi-copyprompts.flag
check "skills flag missing" test ! -f /usr/local/share/pi-copyskills.flag
check "extensions flag missing" test ! -f /usr/local/share/pi-copyextensions.flag
check "themes flag missing" test ! -f /usr/local/share/pi-copythemes.flag

reportResults
