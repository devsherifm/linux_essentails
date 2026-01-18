#!/data/data/com.termux/files/usr/bin/bash

CMD=$(termux-speech-to-text | tr 'A-Z' 'a-z')

case "$CMD" in
  *pause*|*play*|*resume*)
    ~/ytmusic-control.sh toggle ;;
  *next*)
    ~/ytmusic-control.sh next ;;
  *previous*|*back*)
    ~/ytmusic-control.sh prev ;;
  *stop*)
    ~/ytmusic-control.sh stop ;;
  *)
    termux-toast "Command not recognized: $CMD" ;;
esac
