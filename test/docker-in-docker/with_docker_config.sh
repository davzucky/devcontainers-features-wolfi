#!/bin/bash

set -e

source dev-container-features-test-lib

wait_for_file() {
    TARGET_PATH="$1"
    ATTEMPT=0

    while [ ! -f "${TARGET_PATH}" ] && [ "${ATTEMPT}" -lt "10" ]; do
        sleep 1
        ATTEMPT=$((ATTEMPT + 1))
    done
}

TARGET_HOME=$(awk -F= '/^TARGET_HOME=/{gsub(/"/, "", $2); print $2; exit}' /usr/local/share/docker-config-copy.sh)

if [ -z "${TARGET_HOME}" ]; then
    TARGET_HOME="${HOME:-/root}"
fi

TARGET_CONFIG="${TARGET_HOME}/.docker/config.json"
SOURCE_CONFIG="/tmp/docker-in-docker-host-tmp/config.json"

check "docker config copy hook installed" test -f /usr/local/share/docker-config-copy.sh
check "docker config copy flag installed" test -f /usr/local/share/docker-copyconfig.flag

if [ -f "${SOURCE_CONFIG}" ]; then
    wait_for_file "${TARGET_CONFIG}"
    check "docker config copied" test -f "${TARGET_CONFIG}"
    check "docker config content matches" cmp -s "${SOURCE_CONFIG}" "${TARGET_CONFIG}"
else
    check "docker config missing on host" test ! -f "${TARGET_CONFIG}"
fi

reportResults
