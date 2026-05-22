
# pi (pi)

Installs Pi coding agent on Wolfi base images and optionally copies selected Pi agent configuration into the container running user's home.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/pi:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select the Pi coding agent version to install. | string | latest |
| packageManager | Package manager to use when installing Pi. Automatic prefers existing pnpm, then existing npm, then installs npm. | string | automatic |
| nodeVersion | Node.js version to install when Pi installation requires adding Node tooling. Existing node installations are reused. | string | 26 |
| copySettings | Whether to copy Pi settings.json from the host into the container. | boolean | false |
| copyAuth | Whether to copy Pi auth.json from the host into the container. | boolean | false |
| copyModels | Whether to copy Pi models.json from the host into the container. | boolean | false |
| copyKeybindings | Whether to copy Pi keybindings.json from the host into the container. | boolean | false |
| copyInstructions | Whether to copy Pi instruction files (AGENTS.md, SYSTEM.md, APPEND_SYSTEM.md) from the host into the container. | boolean | false |
| copyPrompts | Whether to copy Pi prompt templates from the host into the container. | boolean | false |
| copySkills | Whether to copy Pi skills from the host into the container. | boolean | false |
| copyExtensions | Whether to copy Pi extensions from the host into the container. | boolean | false |
| copyThemes | Whether to copy Pi themes from the host into the container. | boolean | false |
| copyAll | Whether to copy all supported Pi agent content from the host into the container. Package directories, sessions, and logs are never copied. | boolean | false |

## Usage notes

- `version` supports `latest` or an explicit npm package version (with or without a leading `v`).
- `packageManager=automatic` prefers an existing `pnpm`, then an existing `npm`, then installs `npm`. `auto` is accepted as a backward-compatible alias.
- When `pnpm` is used, the installer configures `global-bin-dir` as `/usr/local/bin` and `global-dir` as `/usr/local/share/pnpm/global` before installing Pi.
- If `node` is already installed, the feature does not install another Node.js version. If Node tooling must be installed, `nodeVersion` selects the `nodejs-<version>` package.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/pi` to `/tmp/pi-host-tmp`.
- Use the host scripts in `src/pi/host/pi-agent-copy` (POSIX) and `src/pi/host/pi-agent-copy.cmd` (Windows). Call the shared base name `pi-agent-copy` from `initializeCommand` so each OS resolves the right script.
- The host helper stages supported entries from `${PI_CODING_AGENT_DIR}` when set, otherwise from `~/.pi/agent`, into `${TEMP:-/tmp}/pi/agent`. It creates the temp directory and exits successfully with a warning when Pi is not configured on the host.
- The container startup hook copies selected entries into `${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}` for the container running user.
- Missing selected entries are skipped with a warning.
- `copyAll` includes all supported files and directories: `settings.json`, `auth.json`, `models.json`, `keybindings.json`, `AGENTS.md`, `SYSTEM.md`, `APPEND_SYSTEM.md`, `prompts/`, `skills/`, `extensions/`, and `themes/`.
- Package directories (`npm/`, `git/`), sessions, logs, caches, and temporary files are intentionally never staged or copied.
- Security: `copyAuth` and `copyAll` copy credentials. `copyExtensions` and `copyAll` copy executable extension code. Use these options only with trusted containers and projects.

Example `initializeCommand` (copy both host scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/pi-agent-copy"
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/pi/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
