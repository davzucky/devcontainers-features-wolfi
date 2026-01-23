## Usage notes

- `version` supports `latest`, `stable`, or an explicit version (with or without a leading `v`).
- `copySettings` enables a startup hook that copies `/tmp/claude-host-tmp/settings.json` into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/claude` to `/tmp/claude-host-tmp`.
- Use the host scripts in `src/claude/host/claude-settings-copy` (POSIX) and `src/claude/host/claude-settings-copy.cmd` (Windows). Call the shared base name `claude-settings-copy` from `initializeCommand` so each OS resolves the right script and copy `settings.json` from either:
  - `${CLAUDE_CONFIG_DIR}/settings.json` when `CLAUDE_CONFIG_DIR` is set, or
  - the default storage location (`~/.claude/settings.json` on macOS/Linux, `%USERPROFILE%\.claude\settings.json` on Windows).
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/claude-settings-copy"
```
