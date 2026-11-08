#!/usr/bin/env bash
set -euo pipefail
echo "== syntax =="
bash -n shipgo.sh
echo "== version =="
bash shipgo.sh version | grep -q "shipgo 1.0.0"
echo "== commands =="
bash tests/test-commands.sh
echo "Tests OK"