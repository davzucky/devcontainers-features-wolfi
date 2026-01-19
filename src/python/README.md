
# python (python)

Installs Python and common Python utilities on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/python:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| pythonVersion | Select the Python version to install. | string | 3.13 |
| installRuff | Whether to install Ruff, a fast Python linter and code formatter. | boolean | false |
| installUV | Whether to install uv, a fast Python package installer and resolver. | boolean | false |

## Customizations

### VS Code Extensions

- `ms-python.python`
- `ms-python.vscode-pylance`
- `charliermarsh.ruff`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/python/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
