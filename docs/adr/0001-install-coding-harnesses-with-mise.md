# Install coding harnesses with mise

Use mise to install Claude Code, Cursor Agent, opencode, Pi, and T3 Code to simplify their installers and centralize version selection. Keep each existing harness feature responsible for selecting its tool and version, copying configuration, and starting services where applicable; introduce a separate mise feature as their shared dependency. Node.js and Python remain installed through apk, keeping the runtime installation policy separate from harness installation.

Install mise and the harnesses during the image build into shared locations owned by root. Expose mise and its harness shims on PATH for every container user, including scripts and startup hooks that do not load interactive shell profiles. Feature-selected versions provide system defaults; workspace mise configuration can override them. Update the shared installations by rebuilding the image.

Default mise and harness versions to `latest`, resolved when the installer runs during the image build, while allowing explicit version pins. Release the five migrated harness features as `2.0.0` and the new mise feature as `1.0.0`; unrelated features keep their existing versions.

Remove Pi's `packageManager` and `nodeVersion` feature options. Delegate harness installation to mise; any required Node.js or Python dependencies still come from apk.

The container running user can install additional project-selected versions with `mise install` into their own mise directory, without root. Keep mise's normal trust checks and do not add startup hooks that download tools automatically.
