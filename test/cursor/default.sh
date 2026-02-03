#!/bin/bash

set -e

source dev-container-features-test-lib

check "agent installed" agent --version
check "agent symlink" test -L /usr/local/bin/agent
check "cursor-agent binary" test -f /usr/local/lib/cursor-agent/cursor-agent
check "cursor-agent node" test -f /usr/local/lib/cursor-agent/node
check "cursor-agent index" test -f /usr/local/lib/cursor-agent/index.js

reportResults
