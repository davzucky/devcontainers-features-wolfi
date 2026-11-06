#!/bin/bash
set -e

source dev-container-features-test-lib

BASE_DIR="/tmp/devpod orca/orca's profile"
check "Orca uses mise shim" bash -c 'test "$(command -v orca-ide)" = /usr/local/share/mise/shims/orca-ide'
check "pinned Orca installed" bash -c 'test "$(orca-ide --version)" = "1.4.249"'
check "Orca server running" bash -c 'orca-ide status --json | grep -q "\"reachable\": true"'
check "configured port listening" curl --connect-timeout 1 --max-time 2 -sS -o /dev/null http://127.0.0.1:6769/
check "private profile" test "$(stat -c %a "${BASE_DIR}")" = 700
check "private server log" test "$(stat -c %a "${BASE_DIR}/run/orca.log")" = 600

PID=$(cat "${BASE_DIR}/run/orca.pid")
check "startup hook is idempotent" /usr/local/share/orca-devpod-start.sh
check "same server after restart hook" test "$(cat "${BASE_DIR}/run/orca.pid")" = "${PID}"
check "server still running" kill -0 "${PID}"

reportResults
