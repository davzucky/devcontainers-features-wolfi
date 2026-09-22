## Usage notes

- Version 2 uses the `mise:1` feature. `version` defaults to `latest`; explicit pins remain supported.
- Commands resolve through mise shims. Trusted workspace `mise.toml` files can override the image's default version; run `mise install` as the container running user to install missing versions.
- Pi uses mise's native distribution. The feature also depends on the apk-backed `node:1` feature with Node 24 and npm for Pi package installation.
- Version 2 removes `packageManager` and `nodeVersion`; configure Node through the `node` feature when needed.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/pi` to `/tmp/pi-host-tmp`.
- To copy shared cross-harness skills from `~/.agents/skills`, compose this feature with the `agent-skills` feature. `copySkills` only copies Pi-specific skills from `~/.pi/agent/skills`.
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
