#!/bin/sh
set -e

INSTALL_ZSH="${INSTALLZSH:-"true"}"
CONFIGURE_ZSH_AS_DEFAULT_SHELL="${CONFIGUREZSHASDEFAULTSHELL:-"false"}"
INSTALL_OH_MY_ZSH="${INSTALLOHMYZSH:-"true"}"
INSTALL_OH_MY_ZSH_CONFIG="${INSTALLOHMYZSHCONFIG:-"true"}"
UPGRADE_PACKAGES="${UPGRADEPACKAGES:-"true"}"
USERNAME="${USERNAME:-"automatic"}"
USER_UID="${USERUID:-"automatic"}"
USER_GID="${USERGID:-"automatic"}"

validate_bool() {
    VALUE="$1"
    NAME="$2"
    if [ "${VALUE}" != "true" ] && [ "${VALUE}" != "false" ]; then
        echo "${NAME} must be 'true' or 'false'. Got '${VALUE}'."
        exit 1
    fi
}

validate_bool "${INSTALL_ZSH}" "installZsh"
validate_bool "${CONFIGURE_ZSH_AS_DEFAULT_SHELL}" "configureZshAsDefaultShell"
validate_bool "${INSTALL_OH_MY_ZSH}" "installOhMyZsh"
validate_bool "${INSTALL_OH_MY_ZSH_CONFIG}" "installOhMyZshConfig"
validate_bool "${UPGRADE_PACKAGES}" "upgradePackages"

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must be run as root."
    exit 1
fi

echo "Updating apk index..."
apk update

echo "Installing common packages..."
apk add --no-cache \
    bash \
    bash-completion \
    openssh-client \
    gnupg \
    procps \
    lsof \
    htop \
    net-tools \
    psmisc \
    curl \
    tree \
    wget \
    rsync \
    ca-certificates \
    unzip \
    xz \
    zip \
    nano \
    vim \
    less \
    jq \
    libgcc \
    libstdc++ \
    krb5-libs \
    zlib \
    sudo \
    sed \
    grep \
    shadow \
    strace \
    git

if [ "${INSTALL_ZSH}" = "true" ]; then
    echo "Installing zsh..."
    apk add --no-cache zsh
fi

if [ "${UPGRADE_PACKAGES}" = "true" ]; then
    echo "Upgrading apk packages..."
    apk upgrade
fi

echo "Resolving target user..."
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    if [ "${_REMOTE_USER}" != "" ] && [ "${_REMOTE_USER}" != "root" ] && [ "${_REMOTE_USER}" != "0" ]; then
        if id -u "${_REMOTE_USER}" >/dev/null 2>&1 && [ "$(id -u "${_REMOTE_USER}")" != "0" ]; then
            USERNAME="${_REMOTE_USER}"
        fi
    fi

    if [ "${USERNAME}" = "" ]; then
        POSSIBLE_USERS="devcontainer vscode node codespace $(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"
        for CURRENT_USER in ${POSSIBLE_USERS}; do
            if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
                USERNAME="${CURRENT_USER}"
                break
            fi
        done
    fi

    if [ "${USERNAME}" = "" ]; then
        USERNAME="vscode"
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME="root"
    USER_UID=0
    USER_GID=0
fi

echo "Using username: ${USERNAME}"

GROUP_NAME="${USERNAME}"
if id -u "${USERNAME}" >/dev/null 2>&1; then
    echo "User already exists. Updating settings if needed..."
    if [ "${USER_GID}" != "automatic" ] && [ "${USER_GID}" != "$(id -g "${USERNAME}")" ]; then
        GROUP_NAME="$(id -gn "${USERNAME}")"
        groupmod --gid "${USER_GID}" "${GROUP_NAME}"
        usermod --gid "${USER_GID}" "${USERNAME}"
    fi
    if [ "${USER_UID}" != "automatic" ] && [ "${USER_UID}" != "$(id -u "${USERNAME}")" ]; then
        usermod --uid "${USER_UID}" "${USERNAME}"
    fi
else
    echo "Creating user ${USERNAME}..."
    if [ "${USER_GID}" = "automatic" ]; then
        groupadd "${USERNAME}"
    else
        groupadd --gid "${USER_GID}" "${USERNAME}"
    fi

    if [ "${USER_UID}" = "automatic" ]; then
        useradd -s /bin/bash --gid "${USERNAME}" -m "${USERNAME}"
    else
        useradd -s /bin/bash --uid "${USER_UID}" --gid "${USERNAME}" -m "${USERNAME}"
    fi

    GROUP_NAME="${USERNAME}"
fi

if [ "${USERNAME}" != "root" ]; then
    echo "Configuring passwordless sudo for ${USERNAME}..."
    mkdir -p /etc/sudoers.d
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"
    chmod 0440 "/etc/sudoers.d/${USERNAME}"
fi

if [ "${USERNAME}" = "root" ]; then
    USER_HOME="/root"
else
    USER_HOME="$(awk -F: -v user="${USERNAME}" '$1==user{print $6}' /etc/passwd)"
    if [ "${USER_HOME}" = "" ]; then
        USER_HOME="/home/${USERNAME}"
    fi
    if [ ! -d "${USER_HOME}" ]; then
        mkdir -p "${USER_HOME}"
        chown "${USERNAME}:${GROUP_NAME}" "${USER_HOME}"
    fi
fi

if [ "${INSTALL_ZSH}" = "true" ] && [ "${CONFIGURE_ZSH_AS_DEFAULT_SHELL}" = "true" ]; then
    ZSH_PATH="$(command -v zsh)"
    if [ "${ZSH_PATH}" = "" ]; then
        echo "zsh was requested as default shell but is not installed."
        exit 1
    fi
    echo "Setting ${USERNAME} shell to ${ZSH_PATH}..."
    usermod --shell "${ZSH_PATH}" "${USERNAME}"
fi

if [ "${INSTALL_OH_MY_ZSH}" = "true" ]; then
    if [ "${INSTALL_ZSH}" != "true" ]; then
        echo "installOhMyZsh requires installZsh=true."
        exit 1
    fi

    echo "Installing Oh My Zsh for ${USERNAME}..."
    OH_MY_ZSH_DIR="${USER_HOME}/.oh-my-zsh"
    if [ ! -d "${OH_MY_ZSH_DIR}" ]; then
        git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${OH_MY_ZSH_DIR}"
    fi

    if [ "${INSTALL_OH_MY_ZSH_CONFIG}" = "true" ]; then
        ZSHRC_PATH="${USER_HOME}/.zshrc"
        if [ ! -f "${ZSHRC_PATH}" ]; then
            cat <<'EOF' > "${ZSHRC_PATH}"
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"
EOF
        fi
    fi

    if [ "${USERNAME}" != "root" ]; then
        chown -R "${USERNAME}:${GROUP_NAME}" "${OH_MY_ZSH_DIR}"
        if [ -f "${USER_HOME}/.zshrc" ]; then
            chown "${USERNAME}:${GROUP_NAME}" "${USER_HOME}/.zshrc"
        fi
    fi
fi

echo "Done!"
