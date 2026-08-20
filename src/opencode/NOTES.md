## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
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
- If `opencode` is already installed and `version=latest`, the installer skips upgrading and reuses the existing binary.
