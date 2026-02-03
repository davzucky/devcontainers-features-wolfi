## Usage notes

- This feature expects `git` to be installed on the host (for `initializeCommand`) and in the container (for the copy hook).
- Add an `initializeCommand` to your `devcontainer.json` to export host config in the workspace (commands run in the workspace root):

```json
"initializeCommand": {
    "extractGitGlobals": "git config -l --global --include > .gitconfig.global",
    "extractGitLocals": "git config -l --local --include > .gitconfig.local"
}
```

- The feature copies the exported config during `postAttachCommand` and removes the temporary files after import.
- `copyKeys` accepts `default`, `all`, or a comma-separated list like `user.name,user.email`.
- If `includeLocal` is `true`, local config is applied after global so it can override values.
