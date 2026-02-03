#!/bin/sh
set -e

COPY_KEYS=${COPYKEYS:-"default"}
INCLUDE_LOCAL=${INCLUDELOCAL:-"true"}
GLOBAL_FILE=${GLOBALFILE:-".gitconfig.global"}
LOCAL_FILE=${LOCALFILE:-".gitconfig.local"}

if ! command -v git >/dev/null 2>&1; then
    echo "git is required but was not found in the container."
    echo "Install git in your base image or via another feature, then retry."
    exit 1
fi

echo "Installing git user profile copy hook"
mkdir -p /usr/local/share

cat << EOF > /usr/local/share/git-user-profile.env
COPY_KEYS="${COPY_KEYS}"
INCLUDE_LOCAL="${INCLUDE_LOCAL}"
GLOBAL_FILE="${GLOBAL_FILE}"
LOCAL_FILE="${LOCAL_FILE}"
EOF

cat << 'EOF' > /usr/local/share/git-user-profile-copy.sh
#!/bin/sh
set -e

ENV_FILE="/usr/local/share/git-user-profile.env"
if [ -f "${ENV_FILE}" ]; then
    . "${ENV_FILE}"
fi

COPY_KEYS=${COPY_KEYS:-"default"}
INCLUDE_LOCAL=${INCLUDE_LOCAL:-"true"}
GLOBAL_FILE=${GLOBAL_FILE:-".gitconfig.global"}
LOCAL_FILE=${LOCAL_FILE:-".gitconfig.local"}

should_copy_key() {
    case "${COPY_KEYS}" in
        all)
            return 0
            ;;
        default)
            case "$1" in
                user.name|user.email|user.signingkey|commit.gpgsign)
                    return 0
                    ;;
            esac
            return 1
            ;;
        *)
            OLD_IFS="${IFS}"
            IFS=','
            for key in ${COPY_KEYS}; do
                if [ "${key}" = "$1" ]; then
                    IFS="${OLD_IFS}"
                    return 0
                fi
            done
            IFS="${OLD_IFS}"
            return 1
            ;;
    esac
}

apply_config_file() {
    CONFIG_FILE="$1"
    CONFIG_LABEL="$2"

    if [ ! -f "${CONFIG_FILE}" ]; then
        return 0
    fi

    echo "Parsing ${CONFIG_LABEL} git configuration export"
    while IFS= read -r line; do
        case "${line}" in
            *=*)
                key=${line%%=*}
                value=${line#*=}
                if should_copy_key "${key}"; then
                    echo "Set git config ${key}"
                    git config --global "${key}" "${value}"
                fi
                ;;
        esac
    done < "${CONFIG_FILE}"
}

apply_config_file "${GLOBAL_FILE}" "global"

if [ "${INCLUDE_LOCAL}" = "true" ]; then
    apply_config_file "${LOCAL_FILE}" "local"
fi

rm -f "${GLOBAL_FILE}" "${LOCAL_FILE}"
EOF

chmod +x /usr/local/share/git-user-profile-copy.sh

echo "git user profile copy hook installed"
echo "Done!"
