#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
check "python version" python --version
check "pip version" pip --version

# Check default Python version (3.12)
check "python 3.13" python3.13 --version

# Ensure Ruff and uv are not installed
check "ruff not installed" bash -c "! command -v ruff"
check "uv not installed" bash -c "! command -v uv"

# Report result
reportResults