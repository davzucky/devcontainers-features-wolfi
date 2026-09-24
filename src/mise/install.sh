#!/bin/sh
set -e

VERSION=${VERSION:-"latest"}

case "${VERSION}" in
    latest) ;;
    *)
        if ! printf '%s\n' "${VERSION}" | grep -Eq '^v?[0-9]+\.[0-9]+\.[0-9]+$'; then
            echo "Unsupported mise version: ${VERSION}"
            exit 1
        fi
        ;;
esac

apk update
apk add --no-cache ca-certificates curl libgcc libstdc++

WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT
curl -fsSL https://mise.run -o "${WORKDIR}/install.sh"

# The upstream installer selects the architecture and verifies its checksum.
if [ "${VERSION}" = "latest" ]; then
    unset MISE_VERSION
else
    export MISE_VERSION="${VERSION#v}"
fi
MISE_INSTALL_PATH=/usr/local/bin/mise MISE_INSTALL_SKIP_IF_EXISTS=1 \
    MISE_INSTALL_HELP=0 sh "${WORKDIR}/install.sh"

mkdir -p /etc/mise/conf.d /usr/local/share/mise/shims /etc/profile.d
cat > /etc/profile.d/mise.sh <<'EOF'
export PATH="${HOME}/.local/share/mise/shims:/usr/local/share/mise/shims:/usr/local/bin:${PATH}"
EOF

export PATH="/usr/local/bin:/usr/local/share/mise/shims:${PATH}"
command -v mise
mise --version
