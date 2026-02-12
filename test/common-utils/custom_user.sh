#!/bin/bash

set -e

source dev-container-features-test-lib

check "custom user exists" id -u testuser
check "custom user uid" bash -lc "[ \"$(id -u testuser)\" = \"2001\" ]"
check "custom user gid" bash -lc "[ \"$(id -g testuser)\" = \"2001\" ]"
check "sudoers file for custom user" test -f /etc/sudoers.d/testuser

reportResults
