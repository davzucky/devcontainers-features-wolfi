
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
| useGitAuth | Whether to configure git credential helper for the repository remote using gh. | boolean | false |
| importAuth | Whether to import gh auth host/token pairs from the host export file. | boolean | false |

## Usage notes

- `version` supports `latest` or a specific apk version string (for example, `2.81.0-r0`).
- `importAuth` enables a startup hook that imports host/token pairs from `/tmp/gh-host-tmp/auth-status.tsv` using `gh auth login --with-token`, then removes the export file.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/gh` to `/tmp/gh-host-tmp`.
- Use `src/gh/host/gh-auth-export` (POSIX) and `src/gh/host/gh-auth-export.cmd` (Windows). Call the shared base name `gh-auth-export` from `initializeCommand` so each OS resolves the right script, then set `importAuth` to `true`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/gh-auth-export"
```
- `useGitAuth` configures a scoped git credential helper for the repository `origin` remote when it is HTTPS. SSH remotes are detected and skipped with a warning.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/gh/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
