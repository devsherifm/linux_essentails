#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if [[ -z "${PREFIX:-}" && ! -d /data/data/com.termux/files/usr/bin ]]; then
  echo "ERROR: This script must be run inside Termux."
  exit 1
fi
exec "$SCRIPT_DIR/green_music.sh" "${1:-install-run}"
