#!/bin/bash
set -e

source dev-container-features-test-lib

check "pinned mise version" sh -c '[ "$(mise --version | cut -d " " -f 1)" = 2026.9.10 ]'

reportResults
