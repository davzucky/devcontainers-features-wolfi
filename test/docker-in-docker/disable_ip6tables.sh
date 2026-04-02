#!/bin/bash

set -e

source dev-container-features-test-lib

check "ip6tables flag" bash -c "ps -axww | grep -v grep | grep -F -- '--ip6tables=false'"
check "docker ps" docker ps

reportResults
