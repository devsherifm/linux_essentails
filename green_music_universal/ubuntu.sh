#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [[ ! -r /etc/os-release ]]; then
  echo "ERROR: /etc/os-release not found; Ubuntu could not be detected."
  exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "ubuntu" ]]; then
  echo "ERROR: This script is for Ubuntu. Detected: ${PRETTY_NAME:-unknown}"
  exit 1
fi
exec "$SCRIPT_DIR/green_music.sh" "${1:-install-run}"
