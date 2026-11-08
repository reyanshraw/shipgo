#!/usr/bin/env bash
set -euo pipefail
VERSION="${1:-}"
[ -z "$VERSION" ] && { echo "Usage: scripts/release.sh v1.0.0"; exit 1; }
git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION"
echo "Tagged and pushed $VERSION"