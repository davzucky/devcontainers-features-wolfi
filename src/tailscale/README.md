
# tailscale (tailscale)

Installs Tailscale on Wolfi base images and optionally starts a userspace daemon for DevPod workspaces.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/tailscale:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| autoStart | Whether to start tailscaled from the feature postStartCommand. | boolean | false |
| stateDir | Directory for Tailscale socket, logs, pid, and state file. Mount this from the host to persist the node identity. | string | /persist/devpod-t3/tailscale |
| authKeyEnvVar | Runtime environment variable containing the Tailscale auth key used for first enrollment. | string | TS_AUTHKEY |
| hostname | Optional Tailscale hostname to use during first enrollment. | string |  |
| advertiseTags | Optional comma-separated tags to advertise during first enrollment, for example tag:devpod-t3. | string |  |
| tunMode | Tailscaled --tun mode. Use userspace-networking for unprivileged DevPod containers. | string | userspace-networking |
| serveTarget | Optional local HTTP target to expose with Tailscale Serve, for example http://127.0.0.1:3773. | string |  |
| serveHttpsPort | HTTPS port registered with Tailscale Serve when serveTarget is set. | string | 443 |

## Usage notes

- The feature installs `tailscale` and `tailscaled` from Wolfi packages.
- `autoStart=false` only installs the tools and startup hook. Set `autoStart=true` or runtime `TAILSCALE_AUTO_START=true` to start `tailscaled` at container startup.
- The startup hook uses userspace networking by default so it can run in unprivileged DevPod containers.
- Persist `stateDir` with a host bind mount. The `tailscaled.state` file contains the workspace's Tailscale node identity and must be treated as secret state.
- First enrollment reads the auth key from `authKeyEnvVar`, which defaults to `TS_AUTHKEY`. Do not put auth keys in the feature options.
- `hostname` and `advertiseTags` are used with `tailscale up` during first enrollment. For DevPod T3 workspaces, use names like `t3-hawk` and `tag:devpod-t3`.
- When `serveTarget` is set and the node is authenticated, the hook runs Tailscale Serve in the background, for example `https://t3-hawk.pixiebob-luma.ts.net` for hostname `t3-hawk`.

Example DevPod overlay:

```json
{
    "features": {
        "ghcr.io/davzucky/devcontainers-features-wolfi/tailscale:1": {
            "autoStart": true,
            "stateDir": "/persist/devpod-t3/tailscale",
            "hostname": "t3-hawk",
            "advertiseTags": "tag:devpod-t3",
            "serveTarget": "http://127.0.0.1:3773"
        }
    }
}
```

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/tailscale/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
