#!/bin/bash
set -e

source dev-container-features-test-lib

check "mise on PATH" mise --version
check "mise in non-login shell" sh -c 'command -v mise'

mise install --system jq@1.7.1
mise use --pin --path /etc/mise/conf.d/test.toml jq@1.7.1
mise reshim --system
check "system shim on PATH" sh -c '[ "$(jq --version)" = jq-1.7.1 ]'
printf '#!/bin/sh\nexit 1\n' > /usr/local/bin/jq
chmod +x /usr/local/bin/jq
check "shims precede existing binaries" sh -c '[ "$(jq --version)" = jq-1.7.1 ]'

adduser -D mise-test
check "shared version available to user" su mise-test -s /bin/sh -c '[ "$(jq --version)" = jq-1.7.1 ]'
check "shared tools are read-only" su mise-test -s /bin/sh -c '[ ! -w /usr/local/share/mise/installs ]'
check "project version installs without root" su mise-test -s /bin/sh -c '
    set -e
    cd "$HOME"
    mkdir project
    cd project
    printf "[tools]\njq = \"1.8.1\"\n" > mise.toml
    mise trust
    mise install
    [ "$(jq --version)" = jq-1.8.1 ]
    case "$(mise which jq)" in "$HOME"/*) ;; *) exit 1 ;; esac
    cd ..
    [ "$(jq --version)" = jq-1.7.1 ]
'
check "system default unchanged" sh -c '[ "$(jq --version)" = jq-1.7.1 ]'

reportResults
