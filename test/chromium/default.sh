#!/bin/bash

set -e

source dev-container-features-test-lib

check "chromium package installed" apk info -e chromium
check "chromium binary exists" test -x /usr/bin/chromium

reportResults
