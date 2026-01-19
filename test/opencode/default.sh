#!/bin/bash

set -e

source dev-container-features-test-lib

check "opencode installed" opencode --version

reportResults
