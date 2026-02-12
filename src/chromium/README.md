
# chromium (chromium)

Installs Chromium browser on Wolfi base images.

## Example Usage

```json
"features": {
    "ghcr.io/davzucky/devcontainers-features-wolfi/chromium:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of chromium to install (use 'latest' or a specific apk version). | string | latest |

## Usage notes

- `version` supports `latest` (install current package) or an explicit Wolfi apk package version like `144.0.7559.109-r2`.
- This feature targets headless browser workflows such as Playwright and MCP clients in Wolfi-based devcontainers.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/davzucky/devcontainers-features-wolfi/blob/main/src/chromium/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
