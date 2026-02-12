#!/bin/bash

set -e

source dev-container-features-test-lib

check "zsh default shell for vscode" bash -c "awk -F: '\$1==\"vscode\"{print \$7}' /etc/passwd | grep -qE '/zsh$'"

reportResults
