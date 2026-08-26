#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON="${PYTHON:-python3}"

cd "$ROOT"

if [[ ! -f "$ROOT/pyproject.toml" ]]; then
  echo "ERROR: pyproject.toml was not found." >&2
  echo "Run this installer from the ghmd project root." >&2
  exit 1
fi

# Never leave stale setuptools output around when reinstalling a development copy.
rm -rf "$ROOT/build" "$ROOT/ghmd.egg-info"

if [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == *"/com.termux/"* ]]; then
  echo "Termux detected; installing core ghmd into $ROOT/.venv ..."
  "$PYTHON" -m venv "$ROOT/.venv"
  "$ROOT/.venv/bin/python" -m pip install --upgrade pip
  "$ROOT/.venv/bin/python" -m pip install -e "$ROOT"
  echo
  echo "Installed for Termux. Add this to PATH:"
  echo "  export PATH="$ROOT/.venv/bin:\$PATH""
  echo "Optional terminal-image support:"
  echo "  pip install -e '$ROOT[images]'"
elif command -v pipx >/dev/null 2>&1; then
  echo "Installing ghmd with pipx from: $ROOT"
  pipx install --force "$ROOT"
else
  echo "pipx not found; creating local virtual environment at $ROOT/.venv ..."
  "$PYTHON" -m venv "$ROOT/.venv"
  "$ROOT/.venv/bin/python" -m pip install --upgrade pip
  "$ROOT/.venv/bin/python" -m pip install -e "$ROOT"
  echo
  echo "Installed. Add this to PATH:"
  echo "  export PATH=\"$ROOT/.venv/bin:\$PATH\""
fi

echo
echo "Installed ghmd."
if command -v ghmd >/dev/null 2>&1; then
  ghmd --version || true
else
  echo "ghmd is installed but is not currently on PATH."
  echo "Run: pipx ensurepath"
fi
