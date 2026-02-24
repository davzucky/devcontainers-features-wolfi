#!/bin/bash

set -e

source dev-container-features-test-lib

check "prek installed" prek --version
check "uv installed" uv --version
check "prek binary in /usr/bin" test -x /usr/bin/prek
check "uv tool dir exists" test -d /usr/lib/uv/tools
check "uv tool dir configured" bash -lc "[ \"$(UV_TOOL_DIR=/usr/lib/uv/tools uv tool dir)\" = \"/usr/lib/uv/tools\" ]"

reportResults
