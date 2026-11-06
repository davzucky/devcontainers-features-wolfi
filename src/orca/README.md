
# Orca ADE (orca)

Installs Orca ADE through mise on Wolfi base images and optionally starts a persistent headless Orca server for DevPod workspaces.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/orca:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Orca GitHub release to install: latest or an explicit release version. | string | latest |
| autoStart | Whether to start a headless Orca server from the feature postStartCommand. | boolean | false |
| baseDir | Orca profile directory. Mount this from the host to persist server state. | string | /persist/devpod-orca/orca |
| port | Port for the Orca server to listen on. | string | 6768 |
| pairingAddress | Address advertised to paired clients. This does not change the server's bind address. | string | 127.0.0.1 |

## Usage notes

- Depends on this repository's `mise:1` feature and installs the official [Orca ADE](https://www.onorca.dev/) Linux AppImage through mise's `github:stablyai/orca` backend for x86_64 or aarch64. A postinstall hook extracts the AppImage, so FUSE is not required at runtime.
- Commands resolve through mise shims. Trusted workspace `mise.toml` files can select another release with `orca = "<version>"` under `[tools]`. Run `mise install orca` as the container running user to install it without root.
- The system alias preserves AppImage extraction and the profile wrapper for project installs. Only `orca-ide` is exposed on PATH; Orca's bundled Node does not replace other Node installations.
- The Linux CLI is `orca-ide`. Orca's own terminals also provide `orca`; the feature does not replace an existing command with that name.
- `version` defaults to `latest`. Pin a GitHub release such as `1.4.249` for repeatable builds.
- Orca includes its own Node runtime. Install coding agents separately with this repository's `claude`, `codex`, `opencode`, or `pi` features, then authenticate them inside the container.
- `autoStart=false` only installs Orca and the startup hook. Set `autoStart=true` to start `orca-ide serve` when the container starts.
- Persist `baseDir` with a host bind mount writable by the container running user. The profile holds settings, sessions, credentials, and private pairing links. Repositories and worktrees need their own persistent storage.
- Runtime overrides are `ORCA_AUTO_START`, `ORCA_BASE_DIR`, `ORCA_PORT`, and `ORCA_PAIRING_ADDRESS`. Upstream `ORCA_USER_DATA_PATH` takes precedence over `baseDir` and `ORCA_BASE_DIR`, including for manual CLI commands.
- The server listens on all interfaces. `pairingAddress` only changes the advertised client address. Use a private network, Tailscale, or SSH forwarding, and set it to an address the client can reach.
- Read `${baseDir}/run/orca.log` for the pairing link, then add it in the Orca desktop client's Settings > Remote Orca Servers. Add the container's repository from the client.
- For headless browser automation, compose with this repository's `chromium` feature and set `ORCA_BROWSER_EXECUTABLE=/usr/bin/chromium` in the container environment.

Example DevPod overlay:

```json
{
    "features": {
        "ghcr.io/davzucky/devcontainers-features-wolfi/orca:1": {
            "autoStart": true,
            "baseDir": "/persist/devpod-orca/orca",
            "port": "6768",
            "pairingAddress": "100.64.1.20"
        }
    },
    "mounts": [
        "source=${localEnv:HOME}/.local/share/devpod-orca,target=/persist/devpod-orca,type=bind"
    ]
}
```

Create the host mount directory before starting the workspace. Replace the example pairing address with your server's reachable address.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main//tmp/tmpyew9fl9i/orca/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
