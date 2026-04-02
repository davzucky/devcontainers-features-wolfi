# devcontainer-features-wolfi

Devcontainer features to build on top of [wolfi base images](https://github.com/wolfi-dev/). This is a distroless base image that a lot of application are using to have a lean container without security vulnerabilities. This allow to create the same developement environment that a team may have using devcontainers.

Most of the features available for devcontainers usually expect you to run a debian (or derived) base image. This is not always the case and some teams want to use a more secure and lean base image like wolfi. 

## Features

The following features are available:

- [bash](./src/bash/README.md) - Installs bash and common shell utilities on Wolfi base images
- [chromium](./src/chromium/README.md) - Installs Chromium browser on Wolfi base images
- [common-utils](./src/common-utils/README.md) - Installs common command line utilities, configures users, and optionally sets up Zsh on Wolfi base images (lean Wolfi-native variant)
- [docker-in-docker](./src/docker-in-docker/README.md) - Runs a Docker daemon inside Wolfi-based development containers
- [docker-outside-of-docker](./src/docker-outside-of-docker/README.md) - Reuses the host Docker socket from inside development containers
- [gh](./src/gh/README.md) - Installs GitHub CLI (gh) on Wolfi base images
- [node](./src/node/README.md) - Installs Node.js and common Node.js utilities on Wolfi base images
- [opencode](./src/opencode/README.md) - Installs opencode CLI on Wolfi base images
- [prek](./src/prek/README.md) - Installs prek using uv tool install on Wolfi base images
- [python](./src/python/README.md) - Installs Python and common Python utilities on Wolfi base images
- [user](./src/user/README.md) - Manages user creation and configuration in development containers

Each feature is designed to work seamlessly with Wolfi base images and provides a secure, lean development environment.
