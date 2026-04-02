#!/bin/bash

set -e

source dev-container-features-test-lib

check "docker version" docker --version
check "docker ps" docker ps
check "docker buildx" docker buildx version
check "docker-compose not installed" bash -c "! command -v docker-compose"
check "docker compose unavailable" bash -c "! docker compose version"

reportResults
