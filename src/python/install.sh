#!/bin/sh
set -e

PYTHON_VERSION=${PYTHONVERSION:-"3.13"}
INSTALL_RUFF=${INSTALLRUFF:-"false"}
INSTALL_UV=${INSTALLUV:-"false"}

# Update package list
apk update

# Install Python
if [ "${PYTHON_VERSION}" = "3.13" ] || \
   [ "${PYTHON_VERSION}" = "3.12" ] || \
   [ "${PYTHON_VERSION}" = "3.11" ] || \
   [ "${PYTHON_VERSION}" = "3.10" ]; then
    echo "Installing Python ${PYTHON_VERSION}"
    apk add --no-cache python-${PYTHON_VERSION}-dev py3-pip
else
    echo "Unsupported Python version: ${PYTHON_VERSION}"
    exit 1
fi

# Install Ruff if specified
if [ "${INSTALL_RUFF}" = "true" ]; then
    echo "Installing Ruff..."
    apk add --no-cache ruff
fi
# Install uv if specified
if [ "${INSTALL_UV}" = "true" ]; then
    echo "Installing uv..."
    apk add --no-cache uv
fi

echo "Done!"