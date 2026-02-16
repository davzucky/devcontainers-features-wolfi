#!/bin/bash

set -e

source dev-container-features-test-lib

check "gh installed" gh --version
check "auth import flag missing" test ! -f /usr/local/share/gh-import-auth.flag

reportResults
