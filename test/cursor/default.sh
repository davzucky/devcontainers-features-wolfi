#!/bin/bash

set -e

source dev-container-features-test-lib

check "agent installed" agent --version
check "cursor-agent installed" cursor-agent --version
check "mise resolves cursor-agent" mise which cursor-agent
check "agent follows cursor-agent" test "$(agent --version)" = "$(cursor-agent --version)"

reportResults
