#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
SUMS="$2"
OUT="$3"
mkdir -p "$OUT/homebrew" "$OUT/scoop"
sed -e "s|@VERSION@|$VERSION|g" scripts/homebrew/shipgo.rb.tmpl  > "$OUT/homebrew/shipgo.rb"
sed -e "s|@VERSION@|$VERSION|g" scripts/scoop/shipgo.json.tmpl > "$OUT/scoop/shipgo.json"
echo "Rendered manifests for $VERSION into $OUT"