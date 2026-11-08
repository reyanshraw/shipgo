#!/usr/bin/env bash
set -euo pipefail
shipgo="$PWD/shipgo.sh"
out=$(bash "$shipgo" version)
[[ "$out" == "shipgo 1.0.0" ]] || { echo "version failed: $out"; exit 1; }
echo "command smoke tests passed"