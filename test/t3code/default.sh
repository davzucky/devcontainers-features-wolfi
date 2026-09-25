#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise on PATH" mise --version

check "node installed" node --version
check "npm installed" npm --version
check "t3 installed" t3 --version
check "no build toolchain installed" bash -c '! command -v gcc && ! command -v make && ! command -v python3'
check "startup hook installed" test -x /usr/local/share/t3code-devpod-start.sh
check "startup hook is disabled by default" /usr/local/share/t3code-devpod-start.sh

reportResults
