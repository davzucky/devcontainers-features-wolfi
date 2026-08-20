
# t3code (t3code)

Installs T3 Code CLI on Wolfi base images and optionally starts a persistent headless T3 server for DevPod workspaces.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/t3code:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the T3 Code CLI npm package version to install. | string | latest |
| autoStart | Whether to start a headless T3 Code server from the feature postStartCommand. | boolean | false |
| baseDir | T3CODE_HOME/base directory for server state. Mount this from the host to persist T3 state. | string | /persist/devpod-t3/t3 |
| host | Host/interface for the T3 server to bind. | string | 127.0.0.1 |
| port | Port for the T3 server to listen on. | string | 3773 |
| workspaceDir | Workspace directory passed to T3. Empty means use the postStartCommand working directory. | string |  |

## Usage notes

- The feature depends on this repository's `node` feature with `nodeVersion=24` and `installNpm=true`; it does not install Node.js or npm itself.
- The feature installs native build dependencies needed by T3 Code's `node-pty` dependency, then installs the `t3` npm package globally.
- `autoStart=false` only installs the CLI and startup hook. Set `autoStart=true` or runtime `T3CODE_AUTO_START=true` to start the server at container startup.
- Persist `baseDir` with a host bind mount. It contains T3 settings, pairing/session state, provider settings, logs, and may contain secrets.
- `workspaceDir` should be a path inside the DevPod workspace container. If empty, the post-start working directory is used.
- For mobile access, compose this feature with the `tailscale` feature and expose `http://127.0.0.1:3773` through Tailscale Serve.

Example DevPod overlay:

```json
{
    "features": {
        "ghcr.io/davzucky/devcontainers-features-wolfi/t3code:1": {
            "autoStart": true,
            "baseDir": "/persist/devpod-t3/t3",
            "host": "127.0.0.1",
            "port": "3773"
        }
    }
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/t3code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
