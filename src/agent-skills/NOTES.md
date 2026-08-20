## Usage notes

- This feature copies the shared agent skills directory standard, `~/.agents/skills`, into the container running user's home.
- Including the feature enables copying by default; there are no options.
- The feature bind-mounts `${localEnv:TEMP:/tmp}/agent-skills` to `/tmp/agent-skills-host-tmp`.
- Use the host scripts in `src/agent-skills/host/agent-skills-copy` (POSIX) and `src/agent-skills/host/agent-skills-copy.cmd` (Windows). Call the shared base name `agent-skills-copy` from `initializeCommand` so each OS resolves the right script.
- The host helper stages host `~/.agents/skills` into `${TEMP:-/tmp}/agent-skills/skills`. It creates an empty staging directory and exits successfully with a warning when shared agent skills are not configured on the host.
- The container startup hook replaces the container running user's `~/.agents/skills` with the staged skills directory on each start.
- Source permissions are preserved, including executable bits, and ownership is assigned to the container running user.

Example `initializeCommand` (copy both host scripts into your repo, for example `.devcontainer/`):

```json
"initializeCommand": ".devcontainer/agent-skills-copy"
```
