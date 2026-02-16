#!/bin/bash

set -e

source dev-container-features-test-lib

SOURCE_EXPORT="/tmp/gh-host-tmp/auth-status.tsv"

check "auth import flag installed" test -f /usr/local/share/gh-import-auth.flag
check "auth export consumed" test ! -f "${SOURCE_EXPORT}"

reportResults
