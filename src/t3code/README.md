
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
| nodeVersion | Node.js version to install when T3 Code installation requires adding Node tooling. Existing node installations are reused. | string | 24 |
| autoStart | Whether to start a headless T3 Code server from the feature postStartCommand. | boolean | false |
| baseDir | T3CODE_HOME/base directory for server state. Mount this from the host to persist T3 state. | string | /persist/devpod-t3/t3 |
| host | Host/interface for the T3 server to bind. | string | 127.0.0.1 |
| port | Port for the T3 server to listen on. | string | 3773 |
| workspaceDir | Workspace directory passed to T3. Empty means use the postStartCommand working directory. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/t3code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
