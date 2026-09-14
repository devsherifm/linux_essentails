#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

case "${1:-install-run}" in
  install-run|install|run|rollback|uninstall|help)
    ACTION="${1:-install-run}"
    ;;
  *)
    echo "Usage: $0 [install-run|install|run|rollback|help]"
    exit 2
    ;;
esac

is_termux() {
  [[ -n "${TERMUX_VERSION:-}" || "${PREFIX:-}" == /data/data/com.termux/files/usr || -d /data/data/com.termux/files/usr/bin ]]
}

is_ubuntu() {
  [[ -r /etc/os-release ]] && . /etc/os-release && [[ "${ID:-}" == "ubuntu" ]]
}

if is_termux; then
  PLATFORM="termux"
elif is_ubuntu; then
  PLATFORM="ubuntu"
else
  echo "ERROR: This package supports Termux and Ubuntu Linux only."
  echo "Detected: ${OSTYPE:-unknown}"
  exit 1
fi

APP_DIR="$HOME/.config/green-music"
DATA_DIR="$HOME/Music"
YT_DIR="$HOME/Music/YouTube"
STATE_DIR="$HOME/.local/state/green-music"
STATE_FILE="$STATE_DIR/install-state"

install_common_files() {
  mkdir -p "$APP_DIR" "$DATA_DIR" "$YT_DIR" "$STATE_DIR"
  cp "$SCRIPT_DIR/player.py" "$APP_DIR/player.py"
  cp "$SCRIPT_DIR/config.json" "$APP_DIR/config.json"
}

install_termux() {
  echo "== GREEN MUSIC :: Termux setup =="
  pkg update -y
  pkg install -y python mpv ffmpeg curl ca-certificates

  # Install the current official upstream yt-dlp build. This avoids relying on
  # a potentially stale repository build and keeps YouTube extraction current.
  curl -fL --retry 3 --retry-delay 2 \
    "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
    -o "$PREFIX/bin/yt-dlp"
  chmod 0755 "$PREFIX/bin/yt-dlp"

  install_common_files
  mkdir -p "$PREFIX/bin"
  cat > "$PREFIX/bin/green-music" <<'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
exec python "$HOME/.config/green-music/player.py" "$@"
LAUNCHER
  chmod +x "$PREFIX/bin/green-music"
  echo "termux" > "$STATE_FILE"
}

install_ubuntu() {
  echo "== GREEN MUSIC :: Ubuntu 24.04 setup =="
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
  else
    SUDO="sudo"
  fi

  $SUDO apt update
  $SUDO apt install -y python3 mpv ffmpeg curl ca-certificates

  mkdir -p "$HOME/.local/bin"
  # Ubuntu 24.04's repository yt-dlp can be older than upstream. Install the
  # official upstream standalone build so YouTube extraction stays current.
  curl -fL --retry 3 --retry-delay 2 \
    "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
    -o "$HOME/.local/bin/yt-dlp"
  chmod 0755 "$HOME/.local/bin/yt-dlp"

  install_common_files
  cat > "$HOME/.local/bin/green-music" <<'LAUNCHER'
#!/usr/bin/env bash
exec python3 "$HOME/.config/green-music/player.py" "$@"
LAUNCHER
  chmod +x "$HOME/.local/bin/green-music"
  echo "ubuntu" > "$STATE_FILE"
}

run_player() {
  if [[ "$PLATFORM" == "termux" ]]; then
    exec "$PREFIX/bin/green-music"
  else
    export PATH="$HOME/.local/bin:$PATH"
    exec "$HOME/.local/bin/green-music"
  fi
}

rollback() {
  echo "== GREEN MUSIC :: rollback ($PLATFORM) =="
  if [[ "$PLATFORM" == "termux" ]]; then
    pkill -f "$APP_DIR/player.py" 2>/dev/null || true
    pkill -x mpv 2>/dev/null || true
    rm -f "$PREFIX/bin/green-music"
  else
    pkill -f "$APP_DIR/player.py" 2>/dev/null || true
    pkill -x mpv 2>/dev/null || true
    rm -f "$HOME/.local/bin/green-music" "$HOME/.local/bin/yt-dlp"
  fi
  rm -rf "$APP_DIR" "$STATE_DIR"
  # Never delete ~/Music or user music. Remove the app-created YouTube folder
  # only when it is empty.
  rmdir "$YT_DIR" 2>/dev/null || true
  echo "Rollback complete. Your ~/Music files were not deleted."
}

case "$ACTION" in
  install-run)
    [[ "$PLATFORM" == "termux" ]] && install_termux || install_ubuntu
    echo
    echo "GREEN MUSIC is ready."
    echo "Starting player..."
    echo
    run_player
    ;;
  install)
    [[ "$PLATFORM" == "termux" ]] && install_termux || install_ubuntu
    echo
    echo "Installed successfully. Run: green-music"
    ;;
  run)
    run_player
    ;;
  rollback|uninstall)
    rollback
    ;;
  help)
    cat <<HELP
GREEN MUSIC - universal Termux/Ubuntu installer

No platform selection is required; the script detects Termux or Ubuntu.

  ./green_music.sh              Install missing dependencies, install app, run
  ./green_music.sh install      Install/update dependencies and app only
  ./green_music.sh run          Run the installed player
  ./green_music.sh rollback     Remove Green Music files/launchers

Supported platforms:
  - Termux (Android)
  - Ubuntu Linux (including Ubuntu 24.04 LTS)

Rollback does not delete ~/Music or your music files.
HELP
    ;;
esac
