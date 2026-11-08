#!/usr/bin/env bash
set -euo pipefail
echo "== shellcheck =="
shellcheck -x shipgo.sh scripts/*.sh tests/*.sh
echo "== shfmt =="
shfmt -d -i 2 shipgo.sh scripts/*.sh tests/*.sh
echo "Lint OK"