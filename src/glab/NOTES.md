## Usage notes

- `copyConfig` enables a startup hook that copies `/tmp/glab-host-tmp/config.yml` into `$HOME/.config/glab-cli/config.yml`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/glab` to `/tmp/glab-host-tmp`.
- Use the host scripts in `src/glab/host/glab-config-copy` (POSIX) and `src/glab/host/glab-config-copy.cmd` (Windows). Call the shared base name `glab-config-copy` from `initializeCommand` so each OS resolves the right script and copy `config.yml` from `~/.config/glab-cli/config.yml`.
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/glab-config-copy"
```
- `useGitAuth` configures a scoped git credential helper for the repository `origin` remote when it is HTTPS. SSH remotes are detected and skipped with a warning.
