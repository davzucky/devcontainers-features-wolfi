#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise on PATH" mise --version
check "codex installed" codex --version
check "codex CLI loads" codex --help
check "git installed" git --version
check "ripgrep installed" rg --version
check "bubblewrap installed" bwrap --version
check "no Node dependency" sh -c '! command -v node'

adduser -D codex-test
check "codex available without root" su codex-test -s /bin/sh -c 'codex --version'
check "project version installs without root" su codex-test -s /bin/sh -c '
    set -e
    cd "$HOME"
    mkdir project
    cd project
    printf "[tools]\ncodex = \"0.154.0\"\n" > mise.toml
    mise trust
    mise install codex
    [ "$(codex --version)" = "codex-cli 0.154.0" ]
'

reportResults
