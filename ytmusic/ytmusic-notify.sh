#!/data/data/com.termux/files/usr/bin/bash

MPV_SOCKET="$PREFIX/tmp/mpv-socket"
ID="ytmusic"

TITLE=$(echo '{ "command": ["get_property","media-title"] }' \
  | socat - "$MPV_SOCKET" 2>/dev/null \
  | sed -n 's/.*"data":"\(.*\)".*/\1/p')

termux-notification \
  --id "$ID" \
  --title "🎵 YouTube Music" \
  --content "${TITLE:-Playing}" \
  --type media \
  --media-previous "$HOME/ytmusic-control.sh prev" \
  --media-play "$HOME/ytmusic-control.sh toggle" \
  --media-pause "$HOME/ytmusic-control.sh toggle" \
  --media-next "$HOME/ytmusic-control.sh next" \
  --on-delete "$HOME/ytmusic-control.sh stop"
