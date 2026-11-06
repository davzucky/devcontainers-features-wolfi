#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise installed" mise --version
check "Orca uses mise shim" bash -c 'test "$(command -v orca-ide)" = /usr/local/share/mise/shims/orca-ide'
check "Orca installed" orca-ide --version
check "no bundled Node shim" test ! -e /usr/local/share/mise/shims/node
check "startup hook installed" test -x /usr/local/share/orca-devpod-start.sh
check "autostart disabled" /usr/local/share/orca-devpod-start.sh
check "no server state created" test ! -e /persist/devpod-orca/orca
check "invalid runtime port rejected" bash -c 'ORCA_AUTO_START=true ORCA_PORT=65536 /usr/local/share/orca-devpod-start.sh; test "$?" -ne 0'

adduser -D orca-test
check "Orca available without root" su orca-test -s /bin/sh -c 'orca-ide --version'
check "project version installs without root" su orca-test -s /bin/sh -c '
    set -e
    cd "$HOME"
    mkdir project
    cd project
    printf "[tools]\norca = \"1.4.247\"\n" > mise.toml
    mise trust
    mise install orca
    [ "$(orca-ide --version)" = 1.4.247 ]
    case "$(mise which orca-ide)" in "$HOME"/*) ;; *) exit 1 ;; esac
    [ ! -e "$HOME/.local/share/mise/shims/node" ]
'

reportResults
