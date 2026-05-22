#!/bin/bash
set -e

source dev-container-features-test-lib

check "pnpm installed" command -v pnpm
check "pi command exists" command -v pi
check "pi version works" pi --version
check "copy hook installed" test -f /usr/local/share/pi-agent-copy.sh

reportResults
