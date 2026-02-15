
# gh (gh)

Installs GitHub CLI (gh) on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/gh:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of gh to install (use 'latest' or a specific apk version). | string | latest |
| copyConfig | Whether to copy gh hosts.yml from the host into the container. | boolean | false |
| useGitAuth | Whether to configure git credential helper for the repository remote using gh. | boolean | false |

## Usage notes

- `version` supports `latest` or a specific apk version string (for example, `2.81.0-r0`).
- `copyConfig` enables a startup hook that copies `/tmp/gh-host-tmp/hosts.yml` into `$HOME/.config/gh/hosts.yml`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/gh` to `/tmp/gh-host-tmp`.
- Use the host scripts in `src/gh/host/gh-config-copy` (POSIX) and `src/gh/host/gh-config-copy.cmd` (Windows). Call the shared base name `gh-config-copy` from `initializeCommand` so each OS resolves the right script and copy `hosts.yml` from `~/.config/gh/hosts.yml`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/gh-config-copy"
```
- `useGitAuth` configures a scoped git credential helper for the repository `origin` remote when it is HTTPS. SSH remotes are detected and skipped with a warning.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/gh/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
