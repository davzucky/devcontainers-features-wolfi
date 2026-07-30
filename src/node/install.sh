#!/bin/sh
set -e

NODE_VERSION=${NODEVERSION:-"20"}
INSTALL_NPM=${INSTALLNPM:-"true"}
INSTALL_YARN=${INSTALLYARN:-"false"}
INSTALL_PNPM=${INSTALLPNPM:-"false"}

# Update package list
apk update

# Install Node.js
if [ "${NODE_VERSION}" = "25" ] || \
   [ "${NODE_VERSION}" = "24" ] || \
   [ "${NODE_VERSION}" = "22" ] || \
   [ "${NODE_VERSION}" = "20" ] || \
   [ "${NODE_VERSION}" = "18" ]; then
    echo "Installing Node.js ${NODE_VERSION}"
    apk add --no-cache nodejs-${NODE_VERSION}
else
    echo "Unsupported Node.js version: ${NODE_VERSION}"
    exit 1
fi

# Install npm if specified
if [ "${INSTALL_NPM}" = "true" ]; then
    echo "Installing npm..."
    apk add --no-cache npm
fi

# Install Yarn if specified
if [ "${INSTALL_YARN}" = "true" ]; then
    echo "Installing Yarn..."
    apk add --no-cache yarn
fi

# Install pnpm if specified
if [ "${INSTALL_PNPM}" = "true" ]; then
    if command -v pnpm >/dev/null 2>&1; then
        echo "pnpm already installed"
    else
        echo "Installing pnpm..."
        case "${NODE_VERSION}" in
            18|20)
                PNPM_PACKAGE="pnpm<11"
                ;;
            *)
                PNPM_PACKAGE="pnpm"
                ;;
        esac

        if ! apk add --no-cache "${PNPM_PACKAGE}"; then
            echo "Failed to install ${PNPM_PACKAGE}"
            exit 1
        fi
    fi

    if ! command -v pnpm >/dev/null 2>&1; then
        echo "pnpm installation failed"
        exit 1
    fi
fi

echo "Done!"
