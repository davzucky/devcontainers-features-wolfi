#!/bin/sh
set -e

INSTALL_DOCKER_BUILDX=${INSTALLDOCKERBUILDX:-"true"}
DOCKER_DASH_COMPOSE_VERSION=${DOCKERDASHCOMPOSEVERSION:-"v2"}
AZURE_DNS_AUTO_DETECTION=${AZUREDNSAUTODETECTION:-"true"}
DOCKER_DEFAULT_ADDRESS_POOL=${DOCKERDEFAULTADDRESSPOOL:-""}
DISABLE_IP6_TABLES=${DISABLEIP6TABLES:-"false"}
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
DOCKER_MAJOR="29"
INIT_SCRIPT="/usr/local/share/docker-in-docker-init.sh"

validate_bool() {
    VALUE="$1"
    NAME="$2"

    if [ "${VALUE}" != "true" ] && [ "${VALUE}" != "false" ]; then
        echo "${NAME} must be 'true' or 'false'. Got '${VALUE}'."
        exit 1
    fi
}

resolve_username() {
    CANDIDATE="$1"

    if [ -z "${CANDIDATE}" ] || [ "${CANDIDATE}" = "auto" ] || [ "${CANDIDATE}" = "automatic" ]; then
        if [ -n "${_REMOTE_USER}" ] && [ "${_REMOTE_USER}" != "root" ] && [ "${_REMOTE_USER}" != "0" ]; then
            echo "${_REMOTE_USER}"
            return
        fi

        for CURRENT_USER in devcontainer vscode node codespace; do
            if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
                echo "${CURRENT_USER}"
                return
            fi
        done

        echo "vscode"
        return
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

validate_bool "${INSTALL_DOCKER_BUILDX}" "installDockerBuildx"
validate_bool "${AZURE_DNS_AUTO_DETECTION}" "azureDnsAutoDetection"
validate_bool "${DISABLE_IP6_TABLES}" "disableIp6tables"

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

DOCKER_DEFAULT_IP6_TABLES=""
if [ "${DISABLE_IP6_TABLES}" = "true" ]; then
    DOCKER_DEFAULT_IP6_TABLES="--ip6tables=false"
fi

mkdir -p /usr/local/share
mkdir -p /usr/local/share/docker-in-docker

if [ ! -e /var/run ]; then
    ln -s /run /var/run
fi

install -m755 ./dockerd-entrypoint.sh /usr/local/share/docker-in-docker/dockerd-entrypoint.sh

cat > "${INIT_SCRIPT}" <<EOF
#!/bin/sh
set -e

AZURE_DNS_AUTO_DETECTION='${AZURE_DNS_AUTO_DETECTION}'
DOCKER_DEFAULT_ADDRESS_POOL='${DOCKER_DEFAULT_ADDRESS_POOL}'
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

start_dockerd() {
    if grep -qi 'internal.cloudapp.net' /etc/resolv.conf 2>/dev/null && [ "${AZURE_DNS_AUTO_DETECTION}" = "true" ]; then
        echo "Setting dockerd Azure DNS."
        CUSTOMDNS="--dns 168.63.129.16"
    else
        echo "Not setting dockerd DNS manually."
        CUSTOMDNS=""
    fi

    if [ -n "${DOCKER_DEFAULT_ADDRESS_POOL}" ]; then
        DEFAULT_ADDRESS_POOL="--default-address-pool ${DOCKER_DEFAULT_ADDRESS_POOL}"
    else
        DEFAULT_ADDRESS_POOL=""
    fi

    START_COMMAND="find /run /var/run -iname 'docker*.pid' -delete || :; find /run /var/run -iname 'container*.pid' -delete || :; /usr/bin/dind /usr/local/share/docker-in-docker/dockerd-entrypoint.sh dockerd ${CUSTOMDNS} ${DEFAULT_ADDRESS_POOL} ${DOCKER_DEFAULT_IP6_TABLES} > /tmp/dockerd.log 2>&1 &"

    if [ "$(id -u)" -ne 0 ]; then
        sudo /bin/sh -c "${START_COMMAND}"
    else
        /bin/sh -c "${START_COMMAND}"
    fi
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
        set +e
        sudo_if pkill dockerd
        sudo_if pkill containerd
        set -e
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
