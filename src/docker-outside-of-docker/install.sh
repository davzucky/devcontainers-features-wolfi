#!/bin/sh

set -e

# Parse options from feature configuration in devcontainer.json
INSTALLDOCKER=${INSTALLDOCKER:-"true"}
INSTALLBUILDX=${INSTALLBUILDX:-"true"}
INSTALLDOCKERCOMPOSE=${INSTALLDOCKERCOMPOSE:-"true"}
ENABLE_NONROOT_DOCKER=${ENABLE_NONROOT_DOCKER:-"true"}
SOURCE_SOCKET=/var/run/docker-host.sock
TARGET_SOCKET=/var/run/docker.sock
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

resolve_username() {
    local candidate
    local resolved

    candidate="$1"
    if [ -z "${candidate}" ] || [ "${candidate}" = "auto" ] || [ "${candidate}" = "automatic" ] || [ "${candidate}" = "0" ]; then
        candidate="root"
    fi

    if id -u "${candidate}" >/dev/null 2>&1; then
        echo "${candidate}"
        return
    fi

    resolved="$(getent passwd "${candidate}" | cut -d: -f1)"
    if [ -n "${resolved}" ]; then
        echo "${resolved}"
        return
    fi

    echo "root"
}

FEATURE_USER="$(resolve_username "${USERNAME}")"

echo "Activating feature 'docker-outside-of-docker'"

apk update


# Checks if packages are installed and installs them if not
install_if_not() {
    if [ -z "$(apk list -I "$@")" ]; then
        echo "Install package $@"
        apk add --no-cache "$@"
    fi
}

# If init file already exists, exit
if [ -f "/usr/local/share/docker-init.sh" ]; then
    exit 0
fi

if [ "${INSTALLDOCKER}" = "true" ]; then
    apk --no-cache add docker-cli
fi

if [ "${INSTALLBUILDX}" = "true" ]; then
    apk --no-cache add docker-cli-buildx
fi

if [ "${INSTALLDOCKERCOMPOSE}" = "true" ]; then
    apk --no-cache add docker-compose
fi

# Install requirement to run that script 
install_if_not socat
install_if_not sudo
install_if_not shadow

# Setup a docker group in the event the docker socket's group is not root
if ! grep -qE '^docker:' /etc/group; then
    echo "(*) Creating missing docker group..."
    groupadd --system docker
fi

echo "Using user '${FEATURE_USER}' for docker-outside-of-docker setup"

usermod -aG docker "${FEATURE_USER}"

DOCKER_GID="$(grep -E '^docker:x:[^:]+' /etc/group | cut -d: -f3)"

if [ "${FEATURE_USER}" != "root" ]; then
    echo "${FEATURE_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${FEATURE_USER}"
    chmod 0440 "/etc/sudoers.d/${FEATURE_USER}"
fi

mkdir -p "$(dirname "${SOURCE_SOCKET}")"
touch "${SOURCE_SOCKET}"
ln -s "${SOURCE_SOCKET}" "${TARGET_SOCKET}"

chown -h "${FEATURE_USER}":root "${TARGET_SOCKET}"

## Setup entrypoint script
mkdir -p /usr/local/share

tee /usr/local/share/docker-init.sh > /dev/null \
<< EOF
#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
# Extracted from https://github.com/devcontainers/features/blob/main/src/docker-outside-of-docker/install.sh

set -e

SOCAT_PATH_BASE=/tmp/vscr-docker-from-docker
SOCAT_LOG=\${SOCAT_PATH_BASE}.log
SOCAT_PID=\${SOCAT_PATH_BASE}.pid

# Wrapper function to only use sudo if not already root
sudoIf()
{
    if [ "\$(id -u)" -ne 0 ]; then
        sudo "\$@"
    else
        "\$@"
    fi
}

# Log messages
log()
{
    echo -e "[\$(date)] \$@" | sudoIf tee -a \${SOCAT_LOG} > /dev/null
}

echo -e "\n** \$(date) **" | sudoIf tee -a \${SOCAT_LOG} > /dev/null
log "Ensuring ${_CONTAINER_USER} has access to ${SOURCE_SOCKET} via ${TARGET_SOCKET}"

# If enabled, try to update the docker group with the right GID. If the group is root,
# fall back on using socat to forward the docker socket to another unix socket so
# that we can set permissions on it without affecting the host.
if [ "${ENABLE_NONROOT_DOCKER}" = "true" ] && [ "${SOURCE_SOCKET}" != "${TARGET_SOCKET}" ] && [ "${_CONTAINER_USER}" != "root" ] && [ "${_CONTAINER_USER}" != "0" ]; then
    SOCKET_GID=\$(stat -c '%g' ${SOURCE_SOCKET})
    if [ "\${SOCKET_GID}" != "0" ] && [ "\${SOCKET_GID}" != "${DOCKER_GID}" ] && ! grep -E ".+:x:\${SOCKET_GID}" /etc/group; then
        sudoIf groupmod --gid "\${SOCKET_GID}" docker
    else
        # Enable proxy if not already running
        if [ ! -f "\${SOCAT_PID}" ] || ! ps -p \$(cat \${SOCAT_PID}) > /dev/null; then
            log "Enabling socket proxy."
            log "Proxying ${SOURCE_SOCKET} to ${TARGET_SOCKET} for vscode"
            sudoIf rm -rf ${TARGET_SOCKET}
            (sudoIf socat UNIX-LISTEN:${TARGET_SOCKET},fork,mode=660,user=${_CONTAINER_USER},backlog=128 UNIX-CONNECT:${SOURCE_SOCKET} 2>&1 | sudoIf tee -a \${SOCAT_LOG} > /dev/null & echo "\$!" | sudoIf tee \${SOCAT_PID} > /dev/null)
        else
            log "Socket proxy already running."
        fi
    fi
    log "Success"
fi

# Execute whatever commands were passed in (if any). This allows us
# to set this script to ENTRYPOINT while still executing the default CMD.
set +e
exec "\$@"
EOF

chmod +x /usr/local/share/docker-init.sh
chown "${FEATURE_USER}":root /usr/local/share/docker-init.sh


echo 'Done!'
