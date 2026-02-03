#!/bin/bash

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

check "import git config" /usr/local/share/git-user-profile-copy.sh
check "user.name copied" sh -c 'test "'"'"$(git config --global user.name)"'"'" = "'"'"Host User"'"'"'
check "user.email overridden" sh -c 'test "'"'"$(git config --global user.email)"'"'" = "'"'"local@example.com"'"'"'
check "user.signingkey copied" sh -c 'test "'"'"$(git config --global user.signingkey)"'"'" = "'"'"ABC123"'"'"'
check "commit.gpgsign copied" sh -c 'test "'"'"$(git config --global commit.gpgsign)"'"'" = "'"'"true"'"'"'

# Report result
reportResults
