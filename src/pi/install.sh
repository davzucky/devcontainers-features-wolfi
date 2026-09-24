#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}
COPY_SETTINGS=${COPYSETTINGS:-"false"}
COPY_AUTH=${COPYAUTH:-"false"}
COPY_MODELS=${COPYMODELS:-"false"}
COPY_KEYBINDINGS=${COPYKEYBINDINGS:-"false"}
COPY_INSTRUCTIONS=${COPYINSTRUCTIONS:-"false"}
COPY_PROMPTS=${COPYPROMPTS:-"false"}
COPY_SKILLS=${COPYSKILLS:-"false"}
COPY_EXTENSIONS=${COPYEXTENSIONS:-"false"}
COPY_THEMES=${COPYTHEMES:-"false"}
COPY_ALL=${COPYALL:-"false"}

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

validate_boolean COPY_SETTINGS "${COPY_SETTINGS}"
validate_boolean COPY_AUTH "${COPY_AUTH}"
validate_boolean COPY_MODELS "${COPY_MODELS}"
validate_boolean COPY_KEYBINDINGS "${COPY_KEYBINDINGS}"
validate_boolean COPY_INSTRUCTIONS "${COPY_INSTRUCTIONS}"
validate_boolean COPY_PROMPTS "${COPY_PROMPTS}"
validate_boolean COPY_SKILLS "${COPY_SKILLS}"
validate_boolean COPY_EXTENSIONS "${COPY_EXTENSIONS}"
validate_boolean COPY_THEMES "${COPY_THEMES}"
validate_boolean COPY_ALL "${COPY_ALL}"

apk update
apk add --no-cache ca-certificates libgcc libstdc++

mise install --system "pi@${VERSION#v}"
mise use --pin --path /etc/mise/conf.d/pi.toml "pi@${VERSION#v}"
mise reshim --system
export PATH="/usr/local/share/mise/shims:${PATH}"
command -v pi
pi --version

mkdir -p /usr/local/share

RESOLVED_TARGET_USER="${_REMOTE_USER:-}"
RESOLVED_TARGET_HOME=""

if [ -n "${_REMOTE_USER_HOME:-}" ]; then
    RESOLVED_TARGET_HOME="${_REMOTE_USER_HOME}"
elif [ -n "${RESOLVED_TARGET_USER}" ] && id -u "${RESOLVED_TARGET_USER}" >/dev/null 2>&1; then
    RESOLVED_TARGET_HOME=$(awk -F: -v user="${RESOLVED_TARGET_USER}" '$1==user{print $6}' /etc/passwd)
fi

if [ -z "${RESOLVED_TARGET_HOME}" ]; then
    RESOLVED_TARGET_HOME="${HOME}"
fi

if [ -z "${RESOLVED_TARGET_USER}" ] || [ -z "${RESOLVED_TARGET_HOME}" ]; then
    FALLBACK_USER=$(awk -F: '$3>=1000 && $1!="nobody" {print $1; exit}' /etc/passwd)
    if [ -n "${FALLBACK_USER}" ] && id -u "${FALLBACK_USER}" >/dev/null 2>&1; then
        RESOLVED_TARGET_USER="${FALLBACK_USER}"
        RESOLVED_TARGET_HOME=$(awk -F: -v user="${RESOLVED_TARGET_USER}" '$1==user{print $6}' /etc/passwd)
    fi
fi

if [ -z "${RESOLVED_TARGET_USER}" ] && [ -n "${RESOLVED_TARGET_HOME}" ]; then
    RESOLVED_TARGET_USER=$(awk -F: -v home="${RESOLVED_TARGET_HOME}" '$6==home{print $1; exit}' /etc/passwd)
fi

if [ -z "${RESOLVED_TARGET_HOME}" ]; then
    RESOLVED_TARGET_HOME="/root"
fi

cat <<'HOOK_EOF' > /usr/local/share/pi-agent-copy.sh
#!/bin/sh
set -e

SOURCE_AGENT="/tmp/pi-host-tmp/agent"
TARGET_USER="__TARGET_USER__"
TARGET_HOME="__TARGET_HOME__"
TARGET_AGENT="${PI_CODING_AGENT_DIR:-${TARGET_HOME}/.pi/agent}"
FLAG_DIR="/usr/local/share"

is_enabled() {
    FLAG_NAME="$1"
    [ -f "${FLAG_DIR}/pi-copyall.flag" ] || [ -f "${FLAG_DIR}/pi-copy${FLAG_NAME}.flag" ]
}

own_path() {
    TARGET_PATH="$1"
    if [ "$(id -u)" != "0" ]; then
        return
    fi

    if [ -n "${TARGET_USER}" ] && id -u "${TARGET_USER}" >/dev/null 2>&1; then
        TARGET_GROUP=$(id -gn "${TARGET_USER}" 2>/dev/null || true)
        if [ -n "${TARGET_GROUP}" ]; then
            chown -R "${TARGET_USER}:${TARGET_GROUP}" "${TARGET_PATH}"
        else
            chown -R "${TARGET_USER}" "${TARGET_PATH}"
        fi
    fi
}

secure_path() {
    TARGET_PATH="$1"
    if [ -d "${TARGET_PATH}" ]; then
        find "${TARGET_PATH}" -type d -exec chmod 700 {} +
        find "${TARGET_PATH}" -type f -exec chmod 600 {} +
    elif [ -f "${TARGET_PATH}" ]; then
        chmod 600 "${TARGET_PATH}"
    fi
}

copy_file() {
    FLAG_NAME="$1"
    ENTRY_NAME="$2"

    if ! is_enabled "${FLAG_NAME}"; then
        return
    fi

    SOURCE_PATH="${SOURCE_AGENT}/${ENTRY_NAME}"
    TARGET_PATH="${TARGET_AGENT}/${ENTRY_NAME}"

    if [ ! -f "${SOURCE_PATH}" ]; then
        echo "Pi source entry missing, skipping: ${ENTRY_NAME}"
        return
    fi

    mkdir -p "$(dirname "${TARGET_PATH}")"
    cp "${SOURCE_PATH}" "${TARGET_PATH}"
    secure_path "${TARGET_PATH}"
    own_path "${TARGET_PATH}"
}

copy_dir() {
    FLAG_NAME="$1"
    ENTRY_NAME="$2"

    if ! is_enabled "${FLAG_NAME}"; then
        return
    fi

    SOURCE_PATH="${SOURCE_AGENT}/${ENTRY_NAME}"
    TARGET_PATH="${TARGET_AGENT}/${ENTRY_NAME}"

    if [ ! -d "${SOURCE_PATH}" ]; then
        echo "Pi source entry missing, skipping: ${ENTRY_NAME}"
        return
    fi

    mkdir -p "${TARGET_AGENT}"
    rm -rf "${TARGET_PATH}"
    cp -R "${SOURCE_PATH}" "${TARGET_PATH}"
    secure_path "${TARGET_PATH}"
    own_path "${TARGET_PATH}"
}

mkdir -p "${TARGET_AGENT}"
chmod 700 "${TARGET_AGENT}"
own_path "${TARGET_AGENT}"

if [ ! -d "${SOURCE_AGENT}" ]; then
    echo "Pi source agent directory missing, skipping copy: ${SOURCE_AGENT}"
    exit 0
fi

copy_file settings settings.json
copy_file auth auth.json
copy_file models models.json
copy_file keybindings keybindings.json
copy_file instructions AGENTS.md
copy_file instructions SYSTEM.md
copy_file instructions APPEND_SYSTEM.md
copy_dir prompts prompts
copy_dir skills skills
copy_dir extensions extensions
copy_dir themes themes

secure_path "${TARGET_AGENT}"
own_path "${TARGET_AGENT}"
HOOK_EOF

sed -i "s|__TARGET_USER__|${RESOLVED_TARGET_USER}|g" /usr/local/share/pi-agent-copy.sh
sed -i "s|__TARGET_HOME__|${RESOLVED_TARGET_HOME}|g" /usr/local/share/pi-agent-copy.sh
chmod +x /usr/local/share/pi-agent-copy.sh

set_flag() {
    FLAG_NAME="$1"
    FLAG_VALUE="$2"
    FLAG_PATH="/usr/local/share/pi-copy${FLAG_NAME}.flag"
    if [ "${FLAG_VALUE}" = "true" ]; then
        : > "${FLAG_PATH}"
    else
        rm -f "${FLAG_PATH}"
    fi
}

set_flag settings "${COPY_SETTINGS}"
set_flag auth "${COPY_AUTH}"
set_flag models "${COPY_MODELS}"
set_flag keybindings "${COPY_KEYBINDINGS}"
set_flag instructions "${COPY_INSTRUCTIONS}"
set_flag prompts "${COPY_PROMPTS}"
set_flag skills "${COPY_SKILLS}"
set_flag extensions "${COPY_EXTENSIONS}"
set_flag themes "${COPY_THEMES}"
set_flag all "${COPY_ALL}"

echo "Pi installed successfully"
