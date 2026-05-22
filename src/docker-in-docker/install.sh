#!/bin/sh
set -e

INSTALL_DOCKER_BUILDX=${INSTALLDOCKERBUILDX:-"true"}
DOCKER_DASH_COMPOSE_VERSION=${DOCKERDASHCOMPOSEVERSION:-"v2"}
AZURE_DNS_AUTO_DETECTION=${AZUREDNSAUTODETECTION:-"true"}
DOCKER_DEFAULT_ADDRESS_POOL=${DOCKERDEFAULTADDRESSPOOL:-""}
DISABLE_IP_TABLES=${DISABLEIPTABLES:-"false"}
DISABLE_IP6_TABLES=${DISABLEIP6TABLES:-"false"}
COPY_DOCKER_CONFIG=${COPYDOCKERCONFIG:-"false"}
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
DOCKER_MAJOR="29"
INIT_SCRIPT="/usr/local/share/docker-init.sh"

validate_bool() {
    VALUE="$1"
    NAME="$2"

    if [ "${VALUE}" != "true" ] && [ "${VALUE}" != "false" ]; then
        echo "${NAME} must be 'true' or 'false'. Got '${VALUE}'."
        exit 1
    fi
}

validate_address_pool() {
    VALUE="$1"

    case "${VALUE}" in
        "")
            ;;
        *[!A-Za-z0-9=,./:-]*)
            echo "dockerDefaultAddressPool contains unsupported characters."
            exit 1
            ;;
    esac
}

resolve_username() {
    CANDIDATE="$1"

    if [ -z "${CANDIDATE}" ] || [ "${CANDIDATE}" = "auto" ] || [ "${CANDIDATE}" = "automatic" ]; then
        CANDIDATE="${_REMOTE_USER:-}"

        case "${CANDIDATE}" in
            ''|root|0)
                CANDIDATE=""
                ;;
            *[!0-9]*)
                echo "${CANDIDATE}"
                return
                ;;
        esac

        if [ -z "${CANDIDATE}" ]; then
            for CURRENT_USER in devcontainer vscode node codespace; do
                if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
                    echo "${CURRENT_USER}"
                    return
                fi
            done

            echo "vscode"
            return
        fi
    fi

    if [ "${CANDIDATE}" = "none" ] || [ "${CANDIDATE}" = "root" ] || [ "${CANDIDATE}" = "0" ]; then
        echo "root"
        return
    fi

    case "${CANDIDATE}" in
        ''|*[!0-9]*)
            echo "${CANDIDATE}"
            return
            ;;
        *)
            RESOLVED="$(getent passwd "${CANDIDATE}" | cut -d: -f1)"
            if [ -n "${RESOLVED}" ]; then
                echo "${RESOLVED}"
                return
            fi
            echo "root"
            return
            ;;
    esac
}

ensure_user() {
    if [ "${FEATURE_USER}" = "root" ]; then
        return
    fi

    USER_SHELL="/bin/sh"
    if [ -x /bin/bash ]; then
        USER_SHELL="/bin/bash"
    fi

    if ! id -u "${FEATURE_USER}" >/dev/null 2>&1; then
        echo "(*) Creating missing user '${FEATURE_USER}'..."
        if ! grep -qE "^${FEATURE_USER}:" /etc/group; then
            addgroup "${FEATURE_USER}"
        fi
        adduser -D -h "/home/${FEATURE_USER}" -s "${USER_SHELL}" -G "${FEATURE_USER}" "${FEATURE_USER}"
    fi

    mkdir -p "/home/${FEATURE_USER}"
    chown -R "${FEATURE_USER}:$(id -gn "${FEATURE_USER}")" "/home/${FEATURE_USER}"
}

resolve_user_home() {
    USER_NAME="$1"

    if [ "${USER_NAME}" = "root" ]; then
        echo "/root"
        return
    fi

    HOME_DIR="$(awk -F: -v user="${USER_NAME}" '$1==user{print $6}' /etc/passwd)"
    if [ -n "${HOME_DIR}" ]; then
        echo "${HOME_DIR}"
        return
    fi

    echo "/home/${USER_NAME}"
}

validate_bool "${INSTALL_DOCKER_BUILDX}" "installDockerBuildx"
validate_bool "${AZURE_DNS_AUTO_DETECTION}" "azureDnsAutoDetection"
validate_bool "${DISABLE_IP_TABLES}" "disableIptables"
validate_bool "${DISABLE_IP6_TABLES}" "disableIp6tables"
validate_bool "${COPY_DOCKER_CONFIG}" "copyDockerConfig"
validate_address_pool "${DOCKER_DEFAULT_ADDRESS_POOL}"

case "${DOCKER_DASH_COMPOSE_VERSION}" in
    none|v2)
        ;;
    *)
        echo "dockerDashComposeVersion must be 'v2' or 'none'. Got '${DOCKER_DASH_COMPOSE_VERSION}'."
        exit 1
        ;;
esac

FEATURE_USER="$(resolve_username "${USERNAME}")"

echo "Activating feature 'docker-in-docker'"
echo "Using user '${FEATURE_USER}' for docker-in-docker setup"

apk update

PACKAGES="docker-cli dockerd-${DOCKER_MAJOR} docker-init-${DOCKER_MAJOR} docker-dind-${DOCKER_MAJOR} mount sudo"

if [ "${INSTALL_DOCKER_BUILDX}" = "true" ]; then
    PACKAGES="${PACKAGES} docker-cli-buildx"
fi

if [ "${DOCKER_DASH_COMPOSE_VERSION}" = "v2" ]; then
    PACKAGES="${PACKAGES} docker-compose"
fi

echo "Installing packages: ${PACKAGES}"
apk add --no-cache ${PACKAGES}

ensure_user
FEATURE_HOME="$(resolve_user_home "${FEATURE_USER}")"

if ! grep -qE '^docker:' /etc/group; then
    echo "(*) Creating missing docker group..."
    addgroup -S docker
fi

if [ "${FEATURE_USER}" != "root" ]; then
    if ! id -nG "${FEATURE_USER}" | tr ' ' '\n' | grep -qx docker; then
        addgroup "${FEATURE_USER}" docker
    fi
    mkdir -p /etc/sudoers.d
    if [ ! -f "/etc/sudoers.d/${FEATURE_USER}" ]; then
        echo "${FEATURE_USER} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/${FEATURE_USER}"
        chmod 0440 "/etc/sudoers.d/${FEATURE_USER}"
    fi
fi

DOCKER_DEFAULT_IP_TABLES=""
if [ "${DISABLE_IP_TABLES}" = "true" ]; then
    DOCKER_DEFAULT_IP_TABLES="--iptables=false"
fi

DOCKER_DEFAULT_IP6_TABLES=""
if [ "${DISABLE_IP6_TABLES}" = "true" ]; then
    DOCKER_DEFAULT_IP6_TABLES="--ip6tables=false"
fi

mkdir -p /usr/local/share

cat > /usr/local/share/docker-config-copy.sh <<EOF
#!/bin/sh
set -e

SOURCE_CONFIG="/tmp/docker-in-docker-host-tmp/config.json"
FLAG_FILE="/usr/local/share/docker-copyconfig.flag"
TARGET_USER="${FEATURE_USER}"
TARGET_HOME="${FEATURE_HOME}"

TARGET_DIR="\${TARGET_HOME}/.docker"
TARGET_CONFIG="\${TARGET_DIR}/config.json"

if [ -f "\${FLAG_FILE}" ] && [ -f "\${SOURCE_CONFIG}" ]; then
    mkdir -p "\${TARGET_DIR}"
    cp "\${SOURCE_CONFIG}" "\${TARGET_CONFIG}"

    if [ -n "\${TARGET_USER}" ] && id -u "\${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=\$(id -gn "\${TARGET_USER}" 2>/dev/null || true)
        if [ -n "\${TARGET_GROUP}" ]; then
            chown "\${TARGET_USER}:\${TARGET_GROUP}" "\${TARGET_DIR}" "\${TARGET_CONFIG}"
        else
            chown "\${TARGET_USER}" "\${TARGET_DIR}" "\${TARGET_CONFIG}"
        fi
    fi

    chmod 700 "\${TARGET_DIR}"
    chmod 600 "\${TARGET_CONFIG}"
fi
EOF

chmod +x /usr/local/share/docker-config-copy.sh

if [ "${COPY_DOCKER_CONFIG}" = "true" ]; then
    echo "Enabling Docker config copy"
    : > /usr/local/share/docker-copyconfig.flag
else
    rm -f /usr/local/share/docker-copyconfig.flag
fi

if [ ! -e /var/run ]; then
    ln -s /run /var/run
fi

cat > "${INIT_SCRIPT}" <<EOF
#!/bin/sh
set -e

AZURE_DNS_AUTO_DETECTION='${AZURE_DNS_AUTO_DETECTION}'
DOCKER_DEFAULT_ADDRESS_POOL='${DOCKER_DEFAULT_ADDRESS_POOL}'
DOCKER_DEFAULT_IP_TABLES='${DOCKER_DEFAULT_IP_TABLES}'
DOCKER_DEFAULT_IP6_TABLES='${DOCKER_DEFAULT_IP6_TABLES}'
EOF

cat >> "${INIT_SCRIPT}" <<'EOF'
sudo_if() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

DOCKERD_PID=""

set_cgroup_nesting() {
    if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
        sudo_if mkdir -p /sys/fs/cgroup/init
        sudo_if sh -c 'xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || :'
        sudo_if sh -c "sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control"
    fi
}

resolve_docker_bridge_cidr() {
    if ! grep -q '^nameserver 127\.0\.0\.11$' /etc/resolv.conf 2>/dev/null; then
        return
    fi

    if grep -Eq '^# ExtServers: \[[^]]*172\.17\.0\.1' /etc/resolv.conf 2>/dev/null; then
        echo '172.31.0.1/16'
    fi
}

start_dockerd() {
    set +e
    sudo_if find /run /var/run -iname 'docker*.pid' -delete
    sudo_if find /run /var/run -iname 'container*.pid' -delete
    set -e

    export container=docker

    if [ -d /sys/kernel/security ] && ! mountpoint -q /sys/kernel/security; then
        sudo_if mount -t securityfs none /sys/kernel/security || {
            echo >&2 'Could not mount /sys/kernel/security.'
            echo >&2 'AppArmor detection and --privileged mode might break.'
        }
    fi

    retry_cgroup_nesting=0
    while [ "${retry_cgroup_nesting}" -lt "5" ]; do
        set +e
        set_cgroup_nesting
        cgroup_nesting_rc=$?
        set -e

        if [ "${cgroup_nesting_rc}" -eq "0" ]; then
            break
        fi

        echo "(*) cgroup v2: Failed to enable nesting, retrying..."
        retry_cgroup_nesting=`expr ${retry_cgroup_nesting} + 1`
        sleep 1
    done

    set -- dockerd

    DOCKER_BRIDGE_CIDR="$(resolve_docker_bridge_cidr)"
    if [ -n "${DOCKER_BRIDGE_CIDR}" ]; then
        echo "Setting dockerd bridge CIDR to ${DOCKER_BRIDGE_CIDR} to avoid DNS conflicts with the outer Docker resolver."
        set -- "$@" "--bip=${DOCKER_BRIDGE_CIDR}"
    fi

    if grep -qi 'internal.cloudapp.net' /etc/resolv.conf 2>/dev/null && [ "${AZURE_DNS_AUTO_DETECTION}" = "true" ]; then
        echo "Setting dockerd Azure DNS."
        set -- "$@" --dns 168.63.129.16
    else
        echo "Not setting dockerd DNS manually."
    fi

    if [ -n "${DOCKER_DEFAULT_ADDRESS_POOL}" ]; then
        set -- "$@" "--default-address-pool=${DOCKER_DEFAULT_ADDRESS_POOL}"
    fi

    if [ -n "${DOCKER_DEFAULT_IP_TABLES}" ]; then
        set -- "$@" "${DOCKER_DEFAULT_IP_TABLES}"
    fi

    if [ -n "${DOCKER_DEFAULT_IP6_TABLES}" ]; then
        set -- "$@" "${DOCKER_DEFAULT_IP6_TABLES}"
    fi

    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@" > /tmp/dockerd.log 2>&1 &
    else
        "$@" > /tmp/dockerd.log 2>&1 &
    fi

    DOCKERD_PID=$!
}

stop_dockerd() {
    if [ -z "${DOCKERD_PID}" ]; then
        return
    fi

    set +e
    sudo_if kill "${DOCKERD_PID}" >/dev/null 2>&1
    wait "${DOCKERD_PID}" >/dev/null 2>&1
    set -e

    DOCKERD_PID=""
}

retry_docker_start_count=0
docker_ok="false"

until [ "${docker_ok}" = "true" ] || [ "${retry_docker_start_count}" -eq "5" ];
do
    start_dockerd

    retry_count=0
    until [ "${docker_ok}" = "true" ] || [ "${retry_count}" -eq "10" ];
    do
        sleep 1
        set +e
        docker info >/dev/null 2>&1 && docker_ok="true"
        set -e
        retry_count=`expr ${retry_count} + 1`
    done

    if [ "${docker_ok}" != "true" ] && [ "${retry_docker_start_count}" != "4" ]; then
        echo "(*) Failed to start docker, retrying..."
        stop_dockerd
    fi

    retry_docker_start_count=`expr ${retry_docker_start_count} + 1`
done

if [ "${docker_ok}" != "true" ]; then
    echo "Docker failed to start."
    if [ -f /tmp/dockerd.log ]; then
        cat /tmp/dockerd.log
    fi
    exit 1
fi

exec "$@"
EOF

chmod +x "${INIT_SCRIPT}"
chown "${FEATURE_USER}":root "${INIT_SCRIPT}"

echo "Done!"
