
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
| dockerDefaultAddressPool | Define default address pools for Docker networks. e.g. base=192.168.0.0/16,size=24 | string |  |
| disableIp6tables | Disable ip6tables for the inner Docker daemon. | boolean | false |

## Customizations

### VS Code Extensions

- `ms-azuretools.vscode-docker`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/docker-in-docker/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
