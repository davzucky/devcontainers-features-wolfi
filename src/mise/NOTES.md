## Usage notes

- Installs the official mise release with checksum verification. `version` defaults to `latest` and accepts an explicit release such as `2026.9.10`.
- Mise is installed at `/usr/local/bin/mise`. System tool shims are on the container PATH, including in non-interactive scripts and startup hooks.
- Harness features install shared, root-owned tools under `/usr/local/share/mise/installs` and record defaults in `/etc/mise/conf.d`. Rebuild the image to update these defaults. A cached image layer retains its previously resolved version.
- Trusted workspace `mise.toml` files override system defaults. Run `mise trust` and `mise install` to install a project's additional versions into the container running user's own mise directory. No automatic startup downloads or trust bypasses are configured.
- Shell profiles also add the user's shim directory to PATH. User-installed versions are container-local unless their storage is mounted separately.
- This feature does not install Node.js or Python. Compose their apk-backed features when needed.
