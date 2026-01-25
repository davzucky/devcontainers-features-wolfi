#!/bin/bash

set -e

source dev-container-features-test-lib

check "glab installed" glab --version
check "config copy flag missing" test ! -f /usr/local/share/glab-copyconfig.flag

reportResults
