## Usage notes

- `copyDockerConfig` enables a startup hook that copies `/tmp/docker-in-docker-host-tmp/config.json` into the resolved devcontainer user's `~/.docker/config.json`.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/docker-in-docker` to `/tmp/docker-in-docker-host-tmp`.
- The mount is always configured. Use the host helper script or an `initializeCommand` to ensure `${localEnv:TEMP:/tmp}/docker-in-docker` exists before container startup.
- Use the host scripts in `src/docker-in-docker/host/docker-config-copy` (POSIX) and `src/docker-in-docker/host/docker-config-copy.cmd` (Windows). Call the shared base name `docker-config-copy` from `initializeCommand` so each OS resolves the right script and copy `config.json` from either `${DOCKER_CONFIG}/config.json` when `DOCKER_CONFIG` is set or the default host location (`~/.docker/config.json` on macOS/Linux, `%USERPROFILE%\.docker\config.json` on Windows).
- Example `initializeCommand` (copy both scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/docker-config-copy"
```
