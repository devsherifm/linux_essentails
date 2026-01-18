#!/data/data/com.termux/files/usr/bin/bash

MPV_SOCKET="$PREFIX/tmp/mpv-socket"

send() {
  [ -S "$MPV_SOCKET" ] || exit 0
  printf '{ "command": %s }\n' "$1" | socat - "$MPV_SOCKET" >/dev/null
}

case "$1" in
  toggle)
    send '["cycle","pause"]'
    ~/ytmusic-notify.sh
    ;;
  next)
    send '["playlist-next"]'
    sleep 0.3
    ~/ytmusic-notify.sh
    ;;
  prev)
    send '["playlist-prev"]'
    sleep 0.3
    ~/ytmusic-notify.sh
    ;;
  stop)
    send '["quit"]'
    termux-notification-remove ytmusic
    termux-wake-unlock 2>/dev/null
    ;;
esac
