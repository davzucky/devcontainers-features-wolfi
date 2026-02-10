## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
- The installer ensures `ripgrep` (`rg`) is present because `opencode` requires it.
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
