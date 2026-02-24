#!/bin/bash

set -e

source dev-container-features-test-lib

check "prek pinned version" bash -lc "prek --version | grep -E '0\\.3\\.3'"
check "uv tool dir configured" bash -lc "[ \"$(UV_TOOL_DIR=/usr/lib/uv/tools uv tool dir)\" = \"/usr/lib/uv/tools\" ]"

reportResults
