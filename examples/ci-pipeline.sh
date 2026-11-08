#!/usr/bin/env bash
set -euo pipefail
SHIPGO_YES=1 shipgo sync
SHIPGO_YES=1 shipgo tag "ci-$(date +%Y%m%d%H%M%S)"