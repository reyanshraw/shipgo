#!/usr/bin/env bash
set -euo pipefail
shipgo sync
shipgo release "v${1:?version required}"
shipgo compare main