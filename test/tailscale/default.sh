#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise installed" mise --version
check "tailscale installed" tailscale version
check "tailscaled installed" tailscaled --version
check "tailscale uses mise shim" sh -c '[ "$(command -v tailscale)" = /usr/local/share/mise/shims/tailscale ]'
check "tailscaled uses mise shim" sh -c '[ "$(command -v tailscaled)" = /usr/local/share/mise/shims/tailscaled ]'
check "startup hook installed" test -x /usr/local/share/tailscale-devpod-start.sh
check "startup hook is disabled by default" /usr/local/share/tailscale-devpod-start.sh

adduser -D tailscale-test
check "non-root startup uses mise binaries" su tailscale-test -s /bin/sh -c '
    set -e
    tailscale version
    tailscaled --version
    export TAILSCALE_AUTO_START=true TAILSCALE_STATE_DIR="$HOME/tailscale"
    export TS_AUTHKEY=""
    /usr/local/share/tailscale-devpod-start.sh
    PID=$(cat "$TAILSCALE_STATE_DIR/tailscaled.pid")
    trap '\''kill "$PID"'\'' EXIT
    tailscale --socket="$TAILSCALE_STATE_DIR/tailscaled.sock" version --daemon
    /usr/local/share/tailscale-devpod-start.sh
    [ "$(cat "$TAILSCALE_STATE_DIR/tailscaled.pid")" = "$PID" ]
'

reportResults
