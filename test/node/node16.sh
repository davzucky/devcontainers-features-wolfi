#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "node version" node --version
check "npm version" npm --version

# Check Node.js 16
check "node 16" node --version | grep "v16"

# Ensure Yarn and pnpm are not installed
check "yarn not installed" bash -c "! command -v yarn"
check "pnpm not installed" bash -c "! command -v pnpm"

# Report result
reportResults
