## Usage notes

- Version 2 uses the `mise:1` feature. `version` defaults to `latest`; explicit pins remain supported.
- Commands resolve through mise shims. Trusted workspace `mise.toml` files can override the image's default version; run `mise install` as the container running user to install missing versions.
- Project configuration can select another release with `t3 = "<version>"` under `[tools]`. The system alias uses `npm:t3` and preserves the native-build allowlist for project installs.
- The feature depends on this repository's `node` feature with `nodeVersion=24` and `installNpm=true`; it does not install Node.js or npm itself.
- The feature installs `libatomic` for T3 Code's prebuilt Linux binary, then installs `npm:t3` through mise. It does not install Python or a compiler toolchain. Older T3 releases that compile native dependencies require you to provide those build tools separately.
- `autoStart=false` only installs the CLI and startup hook. Set `autoStart=true` or runtime `T3CODE_AUTO_START=true` to start the server at container startup.
- Persist `baseDir` with a host bind mount. It contains T3 settings, pairing/session state, provider settings, logs, and may contain secrets.
- `workspaceDir` should be a path inside the DevPod workspace container. If empty, the post-start working directory is used.
- For mobile access, compose this feature with the `tailscale` feature and expose `http://127.0.0.1:3773` through Tailscale Serve.

Example DevPod overlay:

```json
{
    "features": {
        "ghcr.io/davzucky/devcontainers-features-wolfi/t3code:2": {
            "autoStart": true,
            "baseDir": "/persist/devpod-t3/t3",
            "host": "127.0.0.1",
            "port": "3773"
        }
    }
}
```
