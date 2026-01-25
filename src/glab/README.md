
# glab (glab)

Installs glab CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/glab:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of glab to install (use 'latest' or a specific apk version). | string | latest |
| copyConfig | Whether to copy glab config.yml from the host into the container. | boolean | false |
| useGitAuth | Whether to configure git credential helper for the repository remote using glab. | boolean | false |

## Usage notes

- `version` supports `latest` or a specific apk version string (for example, `1.81.0-r0`).
- `copyConfig` enables a startup hook that copies `/tmp/glab-host-tmp/config.yml` into `$HOME/.config/glab-cli/config.yml`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/glab` to `/tmp/glab-host-tmp`.
- Use the host scripts in `src/glab/host/glab-config-copy` (POSIX) and `src/glab/host/glab-config-copy.cmd` (Windows). Call the shared base name `glab-config-copy` from `initializeCommand` so each OS resolves the right script and copy `config.yml` from `~/.config/glab-cli/config.yml`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/glab-config-copy"
```
- `useGitAuth` configures a scoped git credential helper for the repository `origin` remote when it is HTTPS. SSH remotes are detected and skipped with a warning.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/glab/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
