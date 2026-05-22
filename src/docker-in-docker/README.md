
# docker-in-docker (docker-in-docker)

Run a Docker daemon inside Wolfi-based development containers using Wolfi packages.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/docker-in-docker:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installDockerBuildx | Install Docker Buildx. | boolean | true |
| dockerDashComposeVersion | Default version of Docker Compose (v2 or none). | string | v2 |
| azureDnsAutoDetection | Allow automatically setting the dockerd DNS server when the installation script detects it is running in Azure. | boolean | true |
| dockerDefaultAddressPool | Define default address pools for Docker networks. e.g. base=192.168.0.0/16,size=24 | string | - |
| disableIptables | Disable iptables for the inner Docker daemon. Useful when nested Docker providers manage networking outside the container. | boolean | false |
| disableIp6tables | Disable ip6tables for the inner Docker daemon. | boolean | false |
| copyDockerConfig | Whether to copy Docker config.json from the host into the container. | boolean | false |

## Customizations

### VS Code Extensions

- `ms-azuretools.vscode-docker`

## Usage notes

- `copyDockerConfig` enables a startup hook that copies `/tmp/docker-in-docker-host-tmp/config.json` into the resolved devcontainer user's `~/.docker/config.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/docker-in-docker` to `/tmp/docker-in-docker-host-tmp`.
- The mount is always configured. Use the host helper script or an `initializeCommand` to ensure `${localEnv:TEMP:/tmp}/docker-in-docker` exists before container startup.
- Use the host scripts in `src/docker-in-docker/host/docker-config-copy` (POSIX) and `src/docker-in-docker/host/docker-config-copy.cmd` (Windows). Call the shared base name `docker-config-copy` from `initializeCommand` so each OS resolves the right script and copy `config.json` from either `${DOCKER_CONFIG}/config.json` when `DOCKER_CONFIG` is set or the default host location (`~/.docker/config.json` on macOS/Linux, `%USERPROFILE%\.docker\config.json` on Windows).
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/docker-config-copy"
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/docker-in-docker/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
