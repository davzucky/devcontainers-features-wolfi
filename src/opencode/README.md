
# opencode (opencode)

Installs opencode CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/opencode:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the opencode CLI version to install. | string | latest |
| copyAuth | Whether to copy opencode auth.json from the host into the container. | boolean | false |
| copyConfig | Whether to copy opencode opencode.json from the host into the container. | boolean | false |

## Usage notes

- Version 2 uses the `mise:1` feature. `version` defaults to `latest`; explicit pins remain supported.
- The system alias pins `opencode` to mise's `aqua:anomalyco/opencode` backend for image and workspace installs. It downloads native binaries and requires no Node.js or npm.
- Commands resolve through mise shims. Trusted workspace `mise.toml` files can override the image's default version; run `mise install` as the container running user to install missing versions.
- `version` supports `latest`, resolved by mise, or an explicit version with or without a leading `v`.
- The installer ensures `ripgrep` (`rg`) is present because `opencode` requires it.
- `copyAuth` enables a startup hook that copies `/tmp/opencode-host-tmp/auth.json` into `$HOME/.local/share/opencode/auth.json`.
- `copyConfig` enables the same startup hook to copy `/tmp/opencode-host-tmp/opencode.json` into `$HOME/.config/opencode/opencode.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/opencode` to `/tmp/opencode-host-tmp`.
- To copy shared cross-harness skills from `~/.agents/skills`, compose this feature with the `agent-skills` feature.
- Use the host scripts in `src/opencode/host/opencode-auth-copy` (POSIX) and `src/opencode/host/opencode-auth-copy.cmd` (Windows). Call the shared base name `opencode-auth-copy` from `initializeCommand` so each OS resolves the right script. The script copies `opencode.json` from `~/.config/opencode/opencode.json` and copies `auth.json` from either:
  - `${OPENCODE_CONFIG_DIR}/auth.json` when `OPENCODE_CONFIG_DIR` is set, or
  - the default storage location (`~/.local/share/opencode/auth.json` on macOS/Linux, `%USERPROFILE%\.local\share\opencode\auth.json` on Windows).
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/opencode-auth-copy"
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main//tmp/tmp5bqll087/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
