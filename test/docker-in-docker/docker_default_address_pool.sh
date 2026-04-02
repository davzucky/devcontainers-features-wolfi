#!/bin/bash

set -e

source dev-container-features-test-lib

check "default address pool flag" bash -c "ps -axww | grep -v grep | grep -F -- '--default-address-pool=base=192.168.0.0/16,size=24'"

reportResults
