#!/bin/sh
set -e

AUTO_START=${AUTOSTART:-"false"}
STATE_DIR=${STATEDIR:-"/persist/devpod-t3/tailscale"}
AUTH_KEY_ENV_VAR=${AUTHKEYENVVAR:-"TS_AUTHKEY"}
HOSTNAME=${HOSTNAME:-""}
ADVERTISE_TAGS=${ADVERTISETAGS:-""}
TUN_MODE=${TUNMODE:-"userspace-networking"}
SERVE_TARGET=${SERVETARGET:-""}
SERVE_HTTPS_PORT=${SERVEHTTPSPORT:-"443"}

validate_boolean() {
    VARIABLE_NAME="$1"
    VARIABLE_VALUE="$2"
    case "${VARIABLE_VALUE}" in
        true|false)
            ;;
        *)
            echo "Unsupported boolean value for ${VARIABLE_NAME}: ${VARIABLE_VALUE}"
            exit 1
            ;;
    esac
}

validate_boolean AUTO_START "${AUTO_START}"

case "${TUN_MODE}" in
    userspace-networking|auto)
        ;;
    *)
        echo "Unsupported Tailscale tun mode: ${TUN_MODE}"
        exit 1
        ;;
esac

case "${SERVE_HTTPS_PORT}" in
    ''|*[!0-9]*)
        echo "serveHttpsPort must be numeric: ${SERVE_HTTPS_PORT}"
        exit 1
        ;;
esac

apk update
apk add --no-cache ca-certificates tailscale

if ! command -v tailscale >/dev/null 2>&1; then
    echo "tailscale installation failed"
    exit 1
fi

if ! command -v tailscaled >/dev/null 2>&1; then
    echo "tailscaled installation failed"
    exit 1
fi

mkdir -p /usr/local/share

cat <<'HOOK_EOF' > /usr/local/share/tailscale-devpod-start.sh
#!/bin/sh
set -e

AUTO_START="__AUTO_START__"
DEFAULT_STATE_DIR="__STATE_DIR__"
DEFAULT_AUTH_KEY_ENV_VAR="__AUTH_KEY_ENV_VAR__"
DEFAULT_HOSTNAME="__HOSTNAME__"
DEFAULT_ADVERTISE_TAGS="__ADVERTISE_TAGS__"
DEFAULT_TUN_MODE="__TUN_MODE__"
DEFAULT_SERVE_TARGET="__SERVE_TARGET__"
DEFAULT_SERVE_HTTPS_PORT="__SERVE_HTTPS_PORT__"

AUTO_START="${TAILSCALE_AUTO_START:-${AUTO_START}}"
STATE_DIR="${TAILSCALE_STATE_DIR:-${DEFAULT_STATE_DIR}}"
AUTH_KEY_ENV_VAR="${TAILSCALE_AUTH_KEY_ENV_VAR:-${DEFAULT_AUTH_KEY_ENV_VAR}}"
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-${DEFAULT_HOSTNAME}}"
ADVERTISE_TAGS="${TAILSCALE_ADVERTISE_TAGS:-${DEFAULT_ADVERTISE_TAGS}}"
TUN_MODE="${TAILSCALE_TUN_MODE:-${DEFAULT_TUN_MODE}}"
SERVE_TARGET="${TAILSCALE_SERVE_TARGET:-${DEFAULT_SERVE_TARGET}}"
SERVE_HTTPS_PORT="${TAILSCALE_SERVE_HTTPS_PORT:-${DEFAULT_SERVE_HTTPS_PORT}}"

if [ "${AUTO_START}" != "true" ]; then
    exit 0
fi

mkdir -p "${STATE_DIR}"
chmod 700 "${STATE_DIR}" 2>/dev/null || true

STATE_FILE="${STATE_DIR}/tailscaled.state"
SOCKET_FILE="${STATE_DIR}/tailscaled.sock"
PID_FILE="${STATE_DIR}/tailscaled.pid"
LOG_FILE="${STATE_DIR}/tailscaled.log"

daemon_ready() {
    tailscale --socket="${SOCKET_FILE}" version --daemon >/dev/null 2>&1
}

authenticated() {
    tailscale --socket="${SOCKET_FILE}" status --peers=false >/dev/null 2>&1
}

if ! daemon_ready; then
    OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
    if [ -n "${OLD_PID}" ] && kill -0 "${OLD_PID}" 2>/dev/null; then
        kill "${OLD_PID}" 2>/dev/null || true
    fi

    echo "Starting tailscaled with state ${STATE_FILE}"
    nohup tailscaled --tun="${TUN_MODE}" --state="${STATE_FILE}" --socket="${SOCKET_FILE}" >"${LOG_FILE}" 2>&1 < /dev/null &
    echo "$!" > "${PID_FILE}"

    READY=0
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        if daemon_ready; then
            READY=1
            break
        fi
        sleep 1
    done

    if [ "${READY}" != "1" ]; then
        echo "tailscaled did not become ready; recent log output follows" >&2
        tail -n 80 "${LOG_FILE}" >&2 2>/dev/null || true
        exit 1
    fi
fi

AUTH_KEY=""
eval "AUTH_KEY=\${${AUTH_KEY_ENV_VAR}:-}"

if ! authenticated && [ -n "${AUTH_KEY}" ]; then
    UP_ARGS="--auth-key=${AUTH_KEY}"
    if [ -n "${TAILSCALE_HOSTNAME}" ]; then
        UP_ARGS="${UP_ARGS} --hostname=${TAILSCALE_HOSTNAME}"
    fi
    if [ -n "${ADVERTISE_TAGS}" ]; then
        UP_ARGS="${UP_ARGS} --advertise-tags=${ADVERTISE_TAGS}"
    fi
    # shellcheck disable=SC2086
    tailscale --socket="${SOCKET_FILE}" up ${UP_ARGS}
fi

if [ -n "${SERVE_TARGET}" ]; then
    if ! authenticated; then
        echo "Tailscale is not authenticated; skipping Tailscale Serve setup" >&2
        exit 0
    fi
    tailscale --socket="${SOCKET_FILE}" serve --bg --https="${SERVE_HTTPS_PORT}" "${SERVE_TARGET}"
fi
HOOK_EOF

sed -i \
    -e "s#__AUTO_START__#${AUTO_START}#g" \
    -e "s#__STATE_DIR__#${STATE_DIR}#g" \
    -e "s#__AUTH_KEY_ENV_VAR__#${AUTH_KEY_ENV_VAR}#g" \
    -e "s#__HOSTNAME__#${HOSTNAME}#g" \
    -e "s#__ADVERTISE_TAGS__#${ADVERTISE_TAGS}#g" \
    -e "s#__TUN_MODE__#${TUN_MODE}#g" \
    -e "s#__SERVE_TARGET__#${SERVE_TARGET}#g" \
    -e "s#__SERVE_HTTPS_PORT__#${SERVE_HTTPS_PORT}#g" \
    /usr/local/share/tailscale-devpod-start.sh

chmod +x /usr/local/share/tailscale-devpod-start.sh

echo "Tailscale installed successfully"
