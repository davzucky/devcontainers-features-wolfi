
# opencode (opencode)

Installs opencode CLI on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/opencode:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the opencode CLI version to install. | string | latest |
| copyAuth | Whether to copy opencode auth.json from the host into the container. | boolean | false |

## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
- `copyAuth` enables a startup hook that symlinks `$HOME/.local/share/opencode` to `/tmp/opencode-host-tmp` for persistent profile and chat history data.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/opencode` to `/tmp/opencode-host-tmp`.
- Use the host scripts in `src/opencode/host/opencode-auth-copy` (POSIX) and `src/opencode/host/opencode-auth-copy.cmd` (Windows). Call the shared base name `opencode-auth-copy` from `initializeCommand` so each OS resolves the right script and source profile data from either:
  - `${OPENCODE_CONFIG_DIR}` when set, or
  - the default storage directory (`~/.local/share/opencode` on macOS/Linux, `%USERPROFILE%\.local\share\opencode` on Windows).
  If the source directory exists, the script links `${TEMP}/opencode` to it. Otherwise it creates an empty `${TEMP}/opencode` directory.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/opencode-auth-copy"
```
- If `opencode` is already installed and `version=latest`, the installer skips upgrading and reuses the existing binary.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
