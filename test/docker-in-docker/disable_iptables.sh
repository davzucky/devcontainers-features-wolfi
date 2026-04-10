#!/bin/bash

set -e

source dev-container-features-test-lib

check "iptables flag" bash -c "ps -axww | grep -v grep | grep -F -- '--iptables=false'"
check "docker ps" docker ps

reportResults
