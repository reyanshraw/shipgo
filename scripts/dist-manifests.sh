#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-}"
SUMS="${2:-}"

if [ -z "$DIR" ] || [ -z "$SUMS" ]; then
  echo "Error: Missing arguments." >&2
  echo "Usage: $0 <source_directory> <output_checksum_file>" >&2
  exit 1
fi

if [ ! -d "$DIR" ]; then
  echo "Error: Directory '$DIR' does not exist." >&2
  exit 1
fi

echo "Generating manifest for files in $DIR..."

cd "$DIR"

find . -type f ! -name "$(basename "$SUMS")" -print0 | sort -z | xargs -0 sha256sum > "$SUMS"

echo "Manifest successfully written to $DIR/$SUMS"
