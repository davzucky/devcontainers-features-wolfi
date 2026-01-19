## Usage notes

- `version` supports `latest` (resolved from the GitHub releases latest tag) or an explicit version (with or without a leading `v`).
- `copyAuth` copies `$HOME/.local/share/opencode/auth.json` into the container user's home when present.
- If `opencode` is already installed, the installer runs `opencode upgrade` and skips reinstalling the binary.
