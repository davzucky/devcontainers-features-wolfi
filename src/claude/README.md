
# claude (claude)

Installs Claude Code CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/claude:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Claude Code CLI version to install. | string | latest |
| copySettings | Whether to copy Claude Code settings.json from the host into the container. | boolean | false |

## Usage notes

- `version` supports `latest`, `stable`, or an explicit version (with or without a leading `v`).
- `copySettings` installs a shell startup hook that copies `/tmp/claude-host-tmp/settings.json` into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/claude/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
