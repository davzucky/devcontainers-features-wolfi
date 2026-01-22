## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
- `copyAuth` enables a startup hook that copies `/tmp/opencode-host-home/auth.json` into `$HOME/.local/share/opencode/auth.json`.
- The feature bind-mounts `${localEnv:HOME}/.local/share/opencode` to `/tmp/opencode-host-home`. Ensure the host directory exists by adding this to your `devcontainer.json`:

```json
"initializeCommand": {
    "mkdir-posix": "mkdir -p $HOME/.local/share/opencode || true"
}
```
- If `opencode` is already installed, the installer runs `opencode upgrade` and skips reinstalling the binary.
