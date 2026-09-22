#!/bin/sh
set -e

# Resolve this repository's feature dependencies locally before publication.
ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
WORKDIR=$(mktemp -d)
trap 'rm -rf "${WORKDIR}"' EXIT
cp -R "${ROOT}/src" "${ROOT}/test" "${WORKDIR}/"
node - "${WORKDIR}/src" <<'EOF'
const fs = require('node:fs');
const path = require('node:path');
const root = process.argv[2];
const prefix = 'ghcr.io/davzucky/devcontainers-features-wolfi/';
const dependencies = {};
for (const feature of fs.readdirSync(root)) {
    const file = path.join(root, feature, 'devcontainer-feature.json');
    const metadata = JSON.parse(fs.readFileSync(file, 'utf8'));
    for (const [dependency, options] of Object.entries(metadata.dependsOn || {})) {
        if (!dependency.startsWith(prefix)) continue;
        const name = dependency.slice(prefix.length).split(':')[0];
        metadata.dependsOn[`./${name}`] = options;
        delete metadata.dependsOn[dependency];
    }
    dependencies[feature] = metadata.dependsOn || {};
    fs.writeFileSync(file, JSON.stringify(metadata, null, 4) + '\n');
}
// The CLI only copies features explicitly listed in each scenario.
for (const feature of fs.readdirSync(path.join(root, '..', 'test'))) {
    const file = path.join(root, '..', 'test', feature, 'scenarios.json');
    if (!fs.existsSync(file)) continue;
    const scenarios = JSON.parse(fs.readFileSync(file, 'utf8'));
    for (const scenario of Object.values(scenarios)) {
        const pending = Object.keys(scenario.features);
        for (const name of pending) {
            for (const [dependency, options] of Object.entries(dependencies[name] || {})) {
                if (!dependency.startsWith('./')) continue;
                const local = dependency.slice(2);
                if (local in scenario.features) continue;
                scenario.features[local] = options;
                pending.push(local);
            }
        }
    }
    fs.writeFileSync(file, JSON.stringify(scenarios, null, 4) + '\n');
}
EOF
devcontainer features test --project-folder "${WORKDIR}" "$@"
