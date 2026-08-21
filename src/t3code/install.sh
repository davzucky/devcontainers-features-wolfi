#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
AUTO_START=${AUTOSTART:-"false"}
BASE_DIR=${BASEDIR:-"/persist/devpod-t3/t3"}
HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"3773"}
WORKSPACE_DIR=${WORKSPACEDIR:-""}

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

case "${PORT}" in
    ''|*[!0-9]*)
        echo "port must be numeric: ${PORT}"
        exit 1
        ;;
esac

apk update
apk add --no-cache ca-certificates curl build-base python-3.13

if ! command -v node >/dev/null 2>&1; then
    echo "node is required. Compose t3code with the node feature."
    exit 1
fi

if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required. Compose t3code with the node feature using installNpm=true."
    exit 1
fi

T3CODE_INSTALLED="false"
if command -v t3 >/dev/null 2>&1; then
    echo "t3 already installed, skipping package install"
    T3CODE_INSTALLED="true"
fi

if [ "${T3CODE_INSTALLED}" = "false" ]; then
    VERSION_TARGET="${VERSION}"
    case "${VERSION_TARGET}" in
        v*)
            VERSION_TARGET=${VERSION_TARGET#v}
            ;;
    esac

    PACKAGE_SPEC="t3@${VERSION_TARGET}"
    echo "Installing T3 Code CLI from ${PACKAGE_SPEC}"
    npm install -g --allow-scripts=node-pty,msgpackr-extract "${PACKAGE_SPEC}"
fi

if ! command -v t3 >/dev/null 2>&1; then
    echo "t3 installation failed"
    exit 1
fi

mkdir -p /usr/local/share

cat <<'HOOK_EOF' > /usr/local/share/t3code-devpod-start.sh
#!/bin/sh
set -e

AUTO_START="__AUTO_START__"
DEFAULT_BASE_DIR="__BASE_DIR__"
DEFAULT_HOST="__HOST__"
DEFAULT_PORT="__PORT__"
DEFAULT_WORKSPACE_DIR="__WORKSPACE_DIR__"

AUTO_START="${T3CODE_AUTO_START:-${AUTO_START}}"
BASE_DIR="${T3CODE_BASE_DIR:-${DEFAULT_BASE_DIR}}"
HOST="${T3CODE_HOST:-${DEFAULT_HOST}}"
PORT="${T3CODE_PORT:-${DEFAULT_PORT}}"
WORKSPACE_DIR="${T3CODE_WORKSPACE_DIR:-${DEFAULT_WORKSPACE_DIR}}"

if [ "${AUTO_START}" != "true" ]; then
    exit 0
fi

if [ -z "${WORKSPACE_DIR}" ]; then
    WORKSPACE_DIR=$(pwd)
fi

mkdir -p "${BASE_DIR}" "${BASE_DIR}/run"
chmod 700 "${BASE_DIR}" 2>/dev/null || true

PID_FILE="${BASE_DIR}/run/t3code.pid"
LOG_FILE="${BASE_DIR}/run/t3code.log"

is_running() {
    PID=$(cat "${PID_FILE}" 2>/dev/null || true)
    if [ -z "${PID}" ] || ! kill -0 "${PID}" 2>/dev/null; then
        return 1
    fi
    curl --connect-timeout 1 --max-time 2 -fsS "http://${HOST}:${PORT}/" >/dev/null 2>&1
}

if is_running; then
    echo "T3 Code server is already running on ${HOST}:${PORT}"
    exit 0
fi

OLD_PID=$(cat "${PID_FILE}" 2>/dev/null || true)
if [ -n "${OLD_PID}" ] && kill -0 "${OLD_PID}" 2>/dev/null; then
    kill "${OLD_PID}" 2>/dev/null || true
fi

mkdir -p "${WORKSPACE_DIR}"

echo "Starting T3 Code server on ${HOST}:${PORT} with base directory ${BASE_DIR}"
nohup env T3CODE_NO_BROWSER=1 t3 serve --host "${HOST}" --port "${PORT}" --base-dir "${BASE_DIR}" "${WORKSPACE_DIR}" >"${LOG_FILE}" 2>&1 < /dev/null &
echo "$!" > "${PID_FILE}"

READY=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    if curl --connect-timeout 1 --max-time 2 -fsS "http://${HOST}:${PORT}/" >/dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 1
done

if [ "${READY}" != "1" ]; then
    echo "T3 Code server did not become ready; recent log output follows" >&2
    tail -n 80 "${LOG_FILE}" >&2 2>/dev/null || true
    exit 1
fi
HOOK_EOF

sed -i \
    -e "s#__AUTO_START__#${AUTO_START}#g" \
    -e "s#__BASE_DIR__#${BASE_DIR}#g" \
    -e "s#__HOST__#${HOST}#g" \
    -e "s#__PORT__#${PORT}#g" \
    -e "s#__WORKSPACE_DIR__#${WORKSPACE_DIR}#g" \
    /usr/local/share/t3code-devpod-start.sh

chmod +x /usr/local/share/t3code-devpod-start.sh

echo "T3 Code installed successfully"
