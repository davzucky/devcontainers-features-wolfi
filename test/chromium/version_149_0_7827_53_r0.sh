#!/bin/bash

set -e

source dev-container-features-test-lib

check "chromium package installed" apk info -e chromium
check "chromium pinned version" bash -lc "apk list --installed chromium | grep 'chromium-149.0.7827.53-r0'"

reportResults
