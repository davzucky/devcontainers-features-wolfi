#!/bin/bash

set -e

source dev-container-features-test-lib

check "chromium package installed" apk info -e chromium
check "chromium pinned version" bash -lc "apk list --installed chromium | grep 'chromium-144.0.7559.109-r2'"

reportResults
