#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "node version" node --version
check "npm version" npm --version

# Check Yarn installation
check "yarn version" yarn --version

# Check pnpm installation
check "pnpm version" pnpm --version

# Report result
reportResults
