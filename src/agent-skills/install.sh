#!/bin/sh
set -e

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

if [ -z "${RESOLVED_TARGET_USER}" ] || [ -z "${RESOLVED_TARGET_HOME}" ] || [ "${RESOLVED_TARGET_HOME}" = "/root" ]; then
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

cat <<'HOOK_EOF' > /usr/local/share/agent-skills-copy.sh
#!/bin/sh
set -e

SOURCE_SKILLS="/tmp/agent-skills-host-tmp/skills"
TARGET_USER="__TARGET_USER__"
TARGET_HOME="__TARGET_HOME__"
TARGET_AGENTS="${TARGET_HOME}/.agents"
TARGET_SKILLS="${TARGET_AGENTS}/skills"

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

mkdir -p "${TARGET_AGENTS}"

if [ ! -d "${SOURCE_SKILLS}" ]; then
    echo "Shared agent skills source directory missing, skipping copy: ${SOURCE_SKILLS}"
    own_path "${TARGET_AGENTS}"
    exit 0
fi

rm -rf "${TARGET_SKILLS}"
cp -R "${SOURCE_SKILLS}" "${TARGET_SKILLS}"
chmod 700 "${TARGET_AGENTS}" "${TARGET_SKILLS}"
own_path "${TARGET_AGENTS}"
HOOK_EOF

sed -i "s|__TARGET_USER__|${RESOLVED_TARGET_USER}|g" /usr/local/share/agent-skills-copy.sh
sed -i "s|__TARGET_HOME__|${RESOLVED_TARGET_HOME}|g" /usr/local/share/agent-skills-copy.sh
chmod +x /usr/local/share/agent-skills-copy.sh

echo "agent-skills installed successfully"
