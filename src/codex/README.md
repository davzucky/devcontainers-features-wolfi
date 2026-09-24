
# codex (codex)

Installs OpenAI Codex CLI through mise on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/codex:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Codex CLI version to install. | string | latest |

## Usage notes

- Uses mise's native Codex distribution; Node.js and npm are not required.
- `version` defaults to `latest`. Explicit release versions, with or without a leading `v`, are supported.
- The image records a shared default in `/etc/mise/conf.d/codex.toml`. Trusted workspace `mise.toml` files can override it with `codex = "<version>"` under `[tools]`. Run `mise install` as the container running user to install missing versions.
- Run `codex` inside the container to sign in, following the [official Codex CLI guide](https://learn.chatgpt.com/docs/codex/cli).
- Installs Git, ripgrep, and bubblewrap through apk. Bubblewrap is the [Linux sandbox prerequisite](https://learn.chatgpt.com/docs/sandboxing); sandbox execution also depends on the container host allowing the required user namespaces.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/codex/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
