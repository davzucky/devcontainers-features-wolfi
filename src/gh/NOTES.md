## Usage notes

- `version` supports `latest` or a specific apk version string (for example, `2.81.0-r0`).
- `copyConfig` enables a startup hook that copies `/tmp/gh-host-tmp/hosts.yml` into `$HOME/.config/gh/hosts.yml`.
- `importAuth` enables a startup hook that imports host/token pairs from `/tmp/gh-host-tmp/auth-status.tsv` using `gh auth login --with-token`, then removes the export file.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/gh` to `/tmp/gh-host-tmp`.
- Use the host scripts in `src/gh/host/gh-config-copy` (POSIX) and `src/gh/host/gh-config-copy.cmd` (Windows). Call the shared base name `gh-config-copy` from `initializeCommand` so each OS resolves the right script and copy `hosts.yml` from `~/.config/gh/hosts.yml`.
- For token-based auth import, use `src/gh/host/gh-auth-export` (POSIX) and `src/gh/host/gh-auth-export.cmd` (Windows), then set `importAuth` to `true`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/gh-config-copy"
```
- `useGitAuth` configures a scoped git credential helper for the repository `origin` remote when it is HTTPS. SSH remotes are detected and skipped with a warning.
