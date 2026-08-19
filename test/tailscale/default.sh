#!/bin/bash
set -e

source dev-container-features-test-lib

check "tailscale installed" tailscale version
check "tailscaled installed" tailscaled --version
check "startup hook installed" test -x /usr/local/share/tailscale-devpod-start.sh
check "startup hook is disabled by default" /usr/local/share/tailscale-devpod-start.sh

reportResults
