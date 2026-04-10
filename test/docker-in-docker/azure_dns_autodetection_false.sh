#!/bin/bash

set -e

source dev-container-features-test-lib

check "azure dns disabled in init" bash -c "grep -F \"AZURE_DNS_AUTO_DETECTION='false'\" /usr/local/share/docker-init.sh"

reportResults
