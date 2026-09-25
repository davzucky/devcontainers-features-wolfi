## Startup and registration

The feature installs `tailscale` and `tailscaled` through mise's
`aqua:tailscale/tailscale` backend. The mise feature is installed automatically as
a dependency. `version` defaults to `latest`, resolved and pinned during the image
build; an explicit release such as `1.102.4` or `v1.102.4` is also supported. Rebuild
the image to update the shared installation. Both binaries are available through
system mise shims to the container running user and startup hook.

By default,
`autoStart=false` only installs the binaries and startup hook. Set `autoStart=true`
to run the hook through the feature's `postStartCommand` on each container start.
The default `userspace-networking` mode works in unprivileged containers.

### Persist the Tailscale identity

Mount a persistent host directory at **`/persist/devpod-t3/tailscale`** inside the
container. This is the default `stateDir`; if you change it, change the mount target
to match. The feature does not create the mount for you.

| Location | Purpose |
| --- | --- |
| Host: `~/.local/state/devcontainers/t3-hawk/tailscale` | Example persistent directory for one workspace |
| Container: `/persist/devpod-t3/tailscale` | Mount target and default `stateDir` |
| Container: `/persist/devpod-t3/tailscale/tailscaled.state` | Saved Tailscale node identity and credentials |

Keep the whole directory across restarts and rebuilds. The saved node identity is
what allows reconnection; `TS_AUTHKEY` is only the enrollment credential. Treat the
directory as secret state, keep it outside the repository, and use a separate
directory for each workspace. Do not share it between running containers or mount
your host's own Tailscale state.

### First startup

1. Create an auth key in the [Tailscale admin console](https://login.tailscale.com/admin/settings/keys).
   For a persistent workspace, use a single-use, non-ephemeral key. If device
   approval is enabled, use a pre-approved key for unattended registration. You can
   assign `tag:devpod-t3` to the key if that tag is configured in your tailnet.
   See [Tailscale's auth-key documentation](https://tailscale.com/docs/features/access-control/auth-keys).
2. Create the host directory before starting the container:

   ```sh
   mkdir -p "$HOME/.local/state/devcontainers/t3-hawk/tailscale"
   chmod 700 "$HOME/.local/state/devcontainers/t3-hawk/tailscale"
   ```

   The container running user must have permission to write to this directory.
   If its UID differs from the host owner, arrange ownership for that user.
3. Merge this example into your `devcontainer.json`. It assumes a local Linux
   Docker host. Replace `t3-hawk` with your workspace name in both the host path
   and hostname:

   ```json
   {
       "features": {
           "ghcr.io/davzucky/devcontainers-features-wolfi/tailscale:1": {
               "autoStart": true,
               "stateDir": "/persist/devpod-t3/tailscale",
               "hostname": "t3-hawk"
           }
       },
       "mounts": [
           "source=${localEnv:HOME}/.local/state/devcontainers/t3-hawk/tailscale,target=/persist/devpod-t3/tailscale,type=bind"
       ],
       "containerEnv": {
           "TS_AUTHKEY": "${localEnv:TS_AUTHKEY}"
       }
   }
   ```

   With a remote Docker host or DevPod provider, the bind source must exist on the
   machine running the container. Configure the persistent mount and runtime
   secret through that provider; the laptop's home directory is not automatically
   available on the remote host.
4. Supply `TS_AUTHKEY` in the environment of the process launching the devcontainer.
   The feature reads this variable but never creates it. For example, in Bash,
   read it without displaying it or putting the value in shell history:

   ```bash
   read -r -s -p "Tailscale auth key: " TS_AUTHKEY
   export TS_AUTHKEY
   ```

   Launch your devcontainer client from that environment. An already-running
   editor may not inherit the new variable. Never put the actual key in feature
   options, build arguments, or committed files.
5. Start the devcontainer. The hook starts `tailscaled`, waits for its socket, then
   calls `tailscale up` with the key if its authentication check fails. Without a
   key, a fresh container starts the daemon but remains unregistered.
6. Verify registration inside the container:

   ```sh
   tailscale --socket=/persist/devpod-t3/tailscale/tailscaled.sock status
   ```

   Daemon logs are in `/persist/devpod-t3/tailscale/tailscaled.log`.

### Later starts and rebuilds

Reuse the same mount and keep `autoStart=true`. The daemon loads its saved identity,
and the hook skips enrollment when its authentication check succeeds. After
successful registration, you can remove the `TS_AUTHKEY` entry from `containerEnv`
and stop injecting the key. Recreate the container to remove an environment value
already stored in its configuration, keeping the state mount intact.

If the state directory is deleted or the node needs reauthentication, supply a
fresh valid auth key. A consumed single-use key cannot register it again; the hook
does not generate replacement keys.

### Optional HTTPS service

Set `serveTarget` to your app's local URL, for example `http://127.0.0.1:3773`, to
configure Tailscale Serve during startup. `serveHttpsPort` defaults to `443`.
The app must also be running. An authenticated node needs no additional auth key
to enable Serve. Your tailnet must have HTTPS certificates enabled; complete any
web consent step before relying on unattended startup. Access is limited by your
tailnet's access rules. See [Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve).
