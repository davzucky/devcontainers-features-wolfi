#!/bin/bash
set -e

source dev-container-features-test-lib

check "tailscale installed" tailscale version
check "startup hook installed" test -x /usr/local/share/tailscale-devpod-start.sh
check "configured state dir present in hook" grep -q '/tmp/devpod-t3/tailscale' /usr/local/share/tailscale-devpod-start.sh
check "configured hostname present in hook" grep -q 't3-hawk' /usr/local/share/tailscale-devpod-start.sh
check "configured tag present in hook" grep -q 'tag:devpod-t3' /usr/local/share/tailscale-devpod-start.sh
check "configured serve target present in hook" grep -q 'http://127.0.0.1:3773' /usr/local/share/tailscale-devpod-start.sh

reportResults
