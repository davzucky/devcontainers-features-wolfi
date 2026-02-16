#!/bin/bash

set -e

source dev-container-features-test-lib

check "curl installed" command -v curl
check "git installed" command -v git
check "iconv installed" command -v iconv
check "bat installed" command -v bat
check "nvim installed" command -v nvim
check "zsh installed" command -v zsh
check "zsh default shell for vscode" bash -c "awk -F: '\$1==\"vscode\"{print \$7}' /etc/passwd | grep -qE '/zsh$'"
check "default user exists" id -u vscode
check "default user in sudo group" bash -lc "id -nG vscode | tr ' ' '\\n' | grep -qx sudo"
check "oh-my-zsh installed for vscode" test -d /home/vscode/.oh-my-zsh
check "sudoers file for vscode" test -f /etc/sudoers.d/vscode

reportResults
