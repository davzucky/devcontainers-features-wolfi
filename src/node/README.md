# node (node)

Installs Node.js and common Node.js utilities on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/node:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| nodeVersion | Select the Node.js version to install. | string | 20 |
| installNpm | Whether to install npm package manager. | boolean | true |
| installYarn | Whether to install Yarn package manager. | boolean | false |
| installPnpm | Whether to install pnpm package manager. | boolean | false |

## Customizations

### VS Code Extensions

- `ms-vscode.vscode-typescript-next`
- `bradlc.vscode-tailwindcss`
- `esbenp.prettier-vscode`

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/node/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
