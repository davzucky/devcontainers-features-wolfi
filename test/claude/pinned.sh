#!/bin/bash
set -e

source dev-container-features-test-lib

check "pinned version" sh -c '[ "$(mise current claude)" = 2.1.2 ]'
check "pinned command works" claude --version

reportResults
