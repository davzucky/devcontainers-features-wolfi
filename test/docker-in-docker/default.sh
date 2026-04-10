#!/bin/bash

set -e

source dev-container-features-test-lib

check "docker version" docker --version
check "docker init script" ls -l /usr/local/share/docker-init.sh
check "docker ps" docker ps
check "docker build" docker build ./
check "docker buildx" docker buildx version
check "docker-compose" docker-compose --version

reportResults
