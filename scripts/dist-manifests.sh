#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-}"
# shellcheck disable=SC2034
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

cd "$DIR"

# SC2094 Fix: Write to a temp file first, then move it to prevent reading/writing the same file
TMP_SUMS=$(mktemp)
find . -type f ! -name "$(basename "$SUMS")" -print0 | sort -z | xargs -0 sha256sum > "$TMP_SUMS"
mv "$TMP_SUMS" "$SUMS"

echo "Manifest successfully written to $DIR/$SUMS"
