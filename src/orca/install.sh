#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
AUTO_START=${AUTOSTART:-"false"}
BASE_DIR=${BASEDIR:-"/persist/devpod-orca/orca"}
PORT=${PORT:-"6768"}
PAIRING_ADDRESS=${PAIRINGADDRESS:-"127.0.0.1"}

case "${VERSION}" in
    latest) ;;
    *)
        if ! printf '%s\n' "${VERSION}" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$'; then
            echo "Unsupported Orca version: ${VERSION}"
            exit 1
        fi
        ;;
esac

case "${AUTO_START}" in
    true|false) ;;
    *) echo "Unsupported autoStart value: ${AUTO_START}"; exit 1 ;;
esac

case "${PORT}" in
    ''|*[!0-9]*|??????*) echo "port must be a number between 1 and 65535: ${PORT}"; exit 1 ;;
esac
if [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
    echo "port must be between 1 and 65535: ${PORT}"
    exit 1
fi

case "$(uname -m)" in
    x86_64) ASSET="orca-linux.AppImage" ;;
    aarch64|arm64) ASSET="orca-linux-arm64.AppImage" ;;
    *) echo "Unsupported Orca architecture: $(uname -m)"; exit 1 ;;
esac

apk update
apk add --no-cache bash ca-certificates curl git libatomic libgcc libstdc++ \
    gtk-3 libnss libnspr alsa-lib mesa-gbm libxcomposite libxdamage libxfixes libxrandr \
    libxkbcommon libudev cups-libs

mkdir -p /usr/local/share

# Quote values as shell literals, including paths containing quotes or spaces.
write_setting() {
    printf "%s='%s'\n" "$1" "$(printf '%s' "$2" | sed "s/'/'\\\\''/g")"
}
{
    write_setting DEFAULT_AUTO_START "${AUTO_START}"
    write_setting DEFAULT_BASE_DIR "${BASE_DIR}"
    write_setting DEFAULT_PORT "${PORT}"
    write_setting DEFAULT_PAIRING_ADDRESS "${PAIRING_ADDRESS}"
} > /usr/local/share/orca-devpod.env

cat > /usr/local/share/orca-mise-postinstall.sh <<'INSTALL_EOF'
#!/bin/sh
set -e

# Keep extraction and the CLI wrapper for project-selected versions too.
cd "${MISE_TOOL_INSTALL_PATH}"
./bin/orca.AppImage --appimage-extract >/dev/null
test -x squashfs-root/resources/bin/orca-ide
rm bin/orca.AppImage

cat > bin/orca-ide <<'CLI_EOF'
#!/bin/sh
set -e
. /usr/local/share/orca-devpod.env
export ORCA_USER_DATA_PATH="${ORCA_USER_DATA_PATH:-${ORCA_BASE_DIR:-${DEFAULT_BASE_DIR}}}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec "${SCRIPT_DIR}/../squashfs-root/resources/bin/orca-ide" "$@"
CLI_EOF
chmod +x bin/orca-ide
INSTALL_EOF
chmod +x /usr/local/share/orca-mise-postinstall.sh

# The alias preserves the AppImage layout and exposes only the Orca CLI.
cat > /etc/mise/conf.d/orca.toml <<EOF
[tool_alias]
orca = 'github:stablyai/orca[asset_pattern=${ASSET},format=raw,rename_exe=orca.AppImage,bin_path=bin,postinstall=/usr/local/share/orca-mise-postinstall.sh]'
EOF

RESOLVED_VERSION=${VERSION#v}
if [ "${RESOLVED_VERSION}" = "latest" ]; then
    RESOLVED_VERSION=$(mise latest orca)
fi
case "${RESOLVED_VERSION}" in
    ''|*[!a-zA-Z0-9.+-]*) echo "Unsupported Orca version: ${RESOLVED_VERSION}"; exit 1 ;;
esac
printf '\n[tools]\norca = "%s"\n' "${RESOLVED_VERSION}" >> /etc/mise/conf.d/orca.toml
mise install --system orca
mise reshim --system
export PATH="/usr/local/share/mise/shims:${PATH}"

cat > /usr/local/share/orca-devpod-start.sh <<'EOF'
#!/bin/sh
set -e
. /usr/local/share/orca-devpod.env

AUTO_START=${ORCA_AUTO_START:-${DEFAULT_AUTO_START}}
case "${AUTO_START}" in
    false) exit 0 ;;
    true) ;;
    *) echo "Unsupported ORCA_AUTO_START value: ${AUTO_START}"; exit 1 ;;
esac

BASE_DIR=${ORCA_USER_DATA_PATH:-${ORCA_BASE_DIR:-${DEFAULT_BASE_DIR}}}
PORT=${ORCA_PORT:-${DEFAULT_PORT}}
PAIRING_ADDRESS=${ORCA_PAIRING_ADDRESS:-${DEFAULT_PAIRING_ADDRESS}}
case "${PORT}" in
    ''|*[!0-9]*|??????*) echo "port must be a number between 1 and 65535: ${PORT}"; exit 1 ;;
esac
if [ "${PORT}" -lt 1 ] || [ "${PORT}" -gt 65535 ]; then
    echo "port must be between 1 and 65535: ${PORT}"
    exit 1
fi

# Logs contain pairing links, so keep all new state private to the running user.
umask 077
mkdir -p "${BASE_DIR}/run"
chmod 700 "${BASE_DIR}" "${BASE_DIR}/run"
export ORCA_USER_DATA_PATH="${BASE_DIR}"
PID_FILE="${BASE_DIR}/run/orca.pid"
LOG_FILE="${BASE_DIR}/run/orca.log"

server_ready() {
    orca-ide status --json 2>/dev/null | grep -q '"reachable": true'
}

if server_ready; then
    echo "Orca server is already running for ${BASE_DIR}"
    exit 0
fi

echo "Starting Orca server on port ${PORT} with profile ${BASE_DIR}"
nohup orca-ide serve --port "${PORT}" --pairing-address "${PAIRING_ADDRESS}" \
    >"${LOG_FILE}" 2>&1 < /dev/null &
PID=$!
printf '%s\n' "${PID}" > "${PID_FILE}"

for _ in $(seq 1 60); do
    if server_ready; then
        echo "Orca server is ready; pairing details are in ${LOG_FILE}"
        exit 0
    fi
    if ! kill -0 "${PID}" 2>/dev/null; then
        break
    fi
    sleep 1
done

echo "Orca server did not become ready. Check ${LOG_FILE} for details." >&2
exit 1
EOF
chmod +x /usr/local/share/orca-devpod-start.sh

command -v orca-ide
orca-ide --version
echo "Orca installed successfully"
