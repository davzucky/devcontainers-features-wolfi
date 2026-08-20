#!/bin/bash
set -e

source dev-container-features-test-lib

check "node installed" node --version
check "npm installed" npm --version
check "t3 installed" t3 --version
check "startup hook installed" test -x /usr/local/share/t3code-devpod-start.sh
check "startup hook is disabled by default" /usr/local/share/t3code-devpod-start.sh

reportResults
