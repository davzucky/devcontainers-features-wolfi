#!/bin/bash
set -e

source dev-container-features-test-lib

check "pinned version" sh -c '[ "$(mise current cursor-agent)" = 2026.01.28-fd13201 ]'
check "pinned command works" cursor-agent --version

reportResults
