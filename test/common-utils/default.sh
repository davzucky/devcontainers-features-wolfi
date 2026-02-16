#!/bin/bash

set -e

source dev-container-features-test-lib

check "curl installed" command -v curl
check "git installed" command -v git
check "zsh installed" command -v zsh
check "default user exists" id -u vscode
check "default user in sudo group" bash -lc "id -nG vscode | tr ' ' '\\n' | grep -qx sudo"
check "oh-my-zsh installed for vscode" test -d /home/vscode/.oh-my-zsh
check "sudoers file for vscode" test -f /etc/sudoers.d/vscode

reportResults
