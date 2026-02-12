#!/bin/bash

set -e

source dev-container-features-test-lib

check "running as root" bash -lc "[ \"$(id -un)\" = \"root\" ]"
check "root uid is 0" bash -lc "[ \"$(id -u)\" = \"0\" ]"
check "no root sudoers drop-in" test ! -f /etc/sudoers.d/root

reportResults
