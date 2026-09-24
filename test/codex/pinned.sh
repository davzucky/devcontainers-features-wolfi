#!/bin/bash
set -e

source dev-container-features-test-lib

check "pinned codex version" sh -c '[ "$(codex --version)" = "codex-cli 0.154.0" ]'
check "pinned mise default" sh -c '[ "$(mise current codex)" = 0.154.0 ]'

reportResults
