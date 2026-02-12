#!/bin/bash

set -e

source dev-container-features-test-lib

check "zsh not installed" bash -c "! command -v zsh"
check "oh-my-zsh not installed" test ! -d /home/vscode/.oh-my-zsh

reportResults
