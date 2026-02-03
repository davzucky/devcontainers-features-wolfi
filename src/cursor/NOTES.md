## Usage notes

- `version` supports `latest` (resolved to `2026.01.28-fd13201`) or an explicit version like `2026.01.28-fd13201`.
- `copyAuth` enables a startup hook that copies `/tmp/cursor-host-tmp/auth.json` into `$HOME/.config/cursor/auth.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/cursor` to `/tmp/cursor-host-tmp`.
- Use the host scripts in `src/cursor/host/cursor-auth-copy` (POSIX) and `src/cursor/host/cursor-auth-copy.cmd` (Windows). Call the shared base name `cursor-auth-copy` from `initializeCommand` so each OS resolves the right script and copy `auth.json` from `~/.config/cursor/auth.json`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/cursor-auth-copy"
```
- The full Cursor Agent package is installed under `/usr/local/lib/cursor-agent`.
- The `agent` entrypoint is installed as `/usr/local/bin/agent`.
- Only Linux x86_64 and arm64 architectures are supported.
