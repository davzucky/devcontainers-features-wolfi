
# cursor (cursor)

Installs Cursor Agent CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/cursor:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Cursor Agent version to install (for example: 'latest' or '2026.01.28-fd13201'). | string | latest |
| copyAuth | Whether to copy Cursor auth.json from the host into the container. | boolean | false |

## Usage notes

- `version` supports `latest` (resolved to `2026.01.28-fd13201`) or an explicit version like `2026.01.28-fd13201`.
- `copyAuth` enables a startup hook that copies `/tmp/cursor-host-tmp/auth.json` into `$HOME/.config/cursor/auth.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/cursor` to `/tmp/cursor-host-tmp`.
- Use the host scripts in `src/cursor/host/cursor-auth-copy` (POSIX) and `src/cursor/host/cursor-auth-copy.cmd` (Windows). Call the shared base name `cursor-auth-copy` from `initializeCommand` so each OS resolves the right script and copy `auth.json` from `~/.config/cursor/auth.json`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/cursor-auth-copy"
```
- The full Cursor Agent package is installed under `/usr/local/lib/cursor-agent`.
- The `agent` entrypoint is installed as `/usr/local/bin/agent`.
- Only Linux x86_64 and arm64 architectures are supported.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/cursor/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
