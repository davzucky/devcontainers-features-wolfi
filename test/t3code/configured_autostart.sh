#!/bin/bash
set -e

source dev-container-features-test-lib

check "t3 installed" t3 --version
check "startup hook installed" test -x /usr/local/share/t3code-devpod-start.sh
check "configured base dir present in hook" grep -q '/tmp/devpod-t3/t3' /usr/local/share/t3code-devpod-start.sh
check "configured port present in hook" grep -q '3773' /usr/local/share/t3code-devpod-start.sh
check "configured workspace dir present in hook" grep -q '/workspaces/hawk' /usr/local/share/t3code-devpod-start.sh
check "t3 server is running" curl -fsS -o /dev/null http://127.0.0.1:3773/

reportResults
