
# claude (claude)

Installs Claude Code CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/claude:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Claude Code CLI version to install. | string | latest |
| copySettings | Whether to copy Claude Code settings.json from the host into the container. | boolean | false |

## Usage notes

- Version 2 uses the `mise:1` feature. `version` defaults to `latest`; explicit pins remain supported.
- Commands resolve through mise shims. Trusted workspace `mise.toml` files can override the image's default version; run `mise install` as the container running user to install missing versions.
- The mise HTTP backend verifies each release against its upstream manifest checksum, including older pinned versions.
- `version` supports `latest`, `stable`, or an explicit version (with or without a leading `v`).
- `copySettings` enables a startup hook that copies `/tmp/claude-host-tmp/settings.json` into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/claude` to `/tmp/claude-host-tmp`.
- The mount is always configured. Use the host helper script or an `initializeCommand` to ensure `${localEnv:TEMP:/tmp}/claude` exists before container startup.
- Use the host scripts in `src/claude/host/claude-settings-copy` (POSIX) and `src/claude/host/claude-settings-copy.cmd` (Windows). Call the shared base name `claude-settings-copy` from `initializeCommand` so each OS resolves the right script and copy `settings.json` from either:
  - `${CLAUDE_CONFIG_DIR}/settings.json` when `CLAUDE_CONFIG_DIR` is set, or
  - the default storage location (`~/.claude/settings.json` on macOS/Linux, `%USERPROFILE%\.claude\settings.json` on Windows).
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/claude-settings-copy"
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/claude/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
