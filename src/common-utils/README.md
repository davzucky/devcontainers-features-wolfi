
# common-utils (common-utils)

Installs common command line utilities, configures a non-root user, and optionally sets up Zsh on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/common-utils:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installZsh | Install zsh shell. | boolean | true |
| configureZshAsDefaultShell | Set zsh as the default shell for the configured user. | boolean | true |
| installOhMyZsh | Install Oh My Zsh for the configured user. | boolean | true |
| installOhMyZshConfig | Create a default .zshrc when installing Oh My Zsh. | boolean | true |
| upgradePackages | Upgrade existing apk packages. | boolean | true |
| username | Enter name of a non-root user to configure or none to skip | string | automatic |
| userUid | Enter UID for non-root user | string | automatic |
| userGid | Enter GID for non-root user | string | automatic |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/common-utils/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
