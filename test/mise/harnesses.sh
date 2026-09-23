#!/bin/bash
set -e

source dev-container-features-test-lib

check "apk Node on PATH" sh -c '[ "$(node -p process.execPath)" = /usr/bin/node ]'
check "mise keeps apk Node" sh -c '[ "$(mise exec -- node -p process.execPath)" = /usr/bin/node ]'
check "no bundled Node shim" test ! -e /usr/local/share/mise/shims/node

adduser -D harness-test
check "all harnesses available without root" su harness-test -s /bin/sh -c '
    set -e
    for command in mise claude codex agent cursor-agent opencode pi t3; do
        "$command" --version
    done
'
check "Cursor project override preserves aliases and Node" su harness-test -s /bin/sh -c '
    set -e
    cd "$HOME"
    mkdir project
    cd project
    printf "[tools]\ncursor-agent = \"2026.01.28-fd13201\"\n" > mise.toml
    mise trust
    mise install cursor-agent
    [ "$(cursor-agent --version)" = 2026.01.28-fd13201 ]
    [ "$(agent --version)" = 2026.01.28-fd13201 ]
    [ "$(mise exec -- node -p process.execPath)" = /usr/bin/node ]
    [ ! -e "$HOME/.local/share/mise/shims/node" ]
'

reportResults
