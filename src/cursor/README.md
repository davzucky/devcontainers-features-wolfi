
# cursor (cursor)

Installs Cursor Agent CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/cursor:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Cursor Agent version to install (for example: 'latest' or '2026.01.28-fd13201'). | string | latest |
| copyAuth | Whether to copy Cursor auth.json from the host into the container. | boolean | false |

## Usage notes

- Version 2 uses the `mise:1` feature. `version` defaults to `latest`; explicit pins remain supported.
- Commands resolve through mise shims. Trusted workspace `mise.toml` files can override the image's default version; run `mise install` as the container running user to install missing versions.
- `version` supports `latest` (resolved from Cursor's current release) or an explicit version like `2026.01.28-fd13201`.
- `copyAuth` enables a startup hook that copies `/tmp/cursor-host-tmp/auth.json` into `$HOME/.config/cursor/auth.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/cursor` to `/tmp/cursor-host-tmp`.
- Use the host scripts in `src/cursor/host/cursor-auth-copy` (POSIX) and `src/cursor/host/cursor-auth-copy.cmd` (Windows). Call the shared base name `cursor-auth-copy` from `initializeCommand` so each OS resolves the right script and copy `auth.json` from `~/.config/cursor/auth.json`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/cursor-auth-copy"
```
- Mise manages the full Cursor Agent package and exposes both command names through shims.
- Only Linux x86_64 and arm64 architectures are supported.

Cursor exposes both `agent` and `cursor-agent`. Its bundled Node runtime stays private to Cursor and does not replace the apk-provided `node` command.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/cursor/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
