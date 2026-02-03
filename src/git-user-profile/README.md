
# git-user-profile (git-user-profile)

Copy selected git user profile settings from the host into the container.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/git-user-profile:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| copyKeys | Keys to copy from exported git config. Use 'default' (user.name, user.email, user.signingkey, commit.gpgsign), 'all', or a comma-separated list. | string | default |
| includeLocal | Also parse the exported local config file after the global file to allow overrides. | boolean | true |
| globalFile | Workspace-relative path to the exported global git config file. | string | .gitconfig.global |
| localFile | Workspace-relative path to the exported local git config file. | string | .gitconfig.local |

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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/git-user-profile/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
