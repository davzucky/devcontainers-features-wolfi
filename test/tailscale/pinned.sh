#!/bin/bash
set -e

source dev-container-features-test-lib

check "pinned tailscale version" sh -c '[ "$(tailscale version | head -n 1)" = 1.102.4 ]'
check "pinned tailscaled version" sh -c '[ "$(tailscaled --version | head -n 1)" = 1.102.4 ]'

reportResults
