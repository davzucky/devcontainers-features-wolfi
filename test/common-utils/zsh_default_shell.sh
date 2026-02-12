#!/bin/bash

set -e

source dev-container-features-test-lib

check "zsh default shell for vscode" awk -F: '$1=="vscode"{print $7}' /etc/passwd | grep -E '/zsh$'

reportResults
