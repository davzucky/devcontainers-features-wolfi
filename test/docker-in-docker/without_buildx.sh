#!/bin/bash

set -e

source dev-container-features-test-lib

check "docker version" docker --version
check "docker ps" docker ps
check "buildx not installed" bash -c "! docker buildx version"
check "docker-compose" docker-compose --version

reportResults
