## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
- `copyAuth` enables a startup hook that copies `${localWorkspaceFolder}/.opencode-auth.json` into `$HOME/.local/share/opencode/auth.json`.
- `initializeCommand` stages `${localWorkspaceFolder}/.opencode-auth.json` from the host `~/.local/share/opencode/auth.json` when it exists, otherwise creates an empty `{}` file.
- `postStartCommand` copies the staged auth file when enabled and always deletes `${localWorkspaceFolder}/.opencode-auth.json` afterwards.
- If `opencode` is already installed, the installer runs `opencode upgrade` and skips reinstalling the binary.
