
# opencode (opencode)

Installs opencode CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/opencode:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the opencode CLI version to install. | string | latest |
| copyAuth | Whether to copy opencode auth.json from the host into the container. | boolean | false |

## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
- `copyAuth` enables a startup hook that copies `/tmp/opencode-host-home/auth.json` into `$HOME/.local/share/opencode/auth.json`.
- The feature bind-mounts `${localEnv:HOME}/.local/share/opencode` to `/tmp/opencode-host-home`. Ensure the host directory exists by adding this to your `devcontainer.json`:

```json
"initializeCommand": {
    "mkdir-posix": "mkdir -p $HOME/.local/share/opencode || true",
    "mkdir-windows": "powershell -Command \"New-Item -ItemType Directory -Force $env:USERPROFILE\\.local\\share\\opencode | Out-Null\""
}
```
- If `opencode` is already installed, the installer runs `opencode upgrade` and skips reinstalling the binary.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
