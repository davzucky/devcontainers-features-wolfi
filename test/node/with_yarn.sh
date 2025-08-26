#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "node version" node --version
check "npm version" npm --version

# Check Yarn installation
check "yarn version" yarn --version

# Ensure pnpm is not installed
check "pnpm not installed" bash -c "! command -v pnpm"

# Report result
reportResults
