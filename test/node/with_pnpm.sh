#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "node version" node --version
check "npm version" npm --version

# Check pnpm installation
check "pnpm version" pnpm --version

# Ensure Yarn is not installed
check "yarn not installed" bash -c "! command -v yarn"

# Report result
reportResults
