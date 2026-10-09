#!/bin/sh
set -eu

PICS="${XDG_PICTURES_DIR:-$HOME/Pictures}"
mkdir -p "$PICS"
capture=$(mktemp "$PICS/screenshot-$(date +%Y%m%d-%H%M%S)-XXXXXX.png")
if ! grim "$capture"; then
    rm -f "$capture"
    exit 1
fi
wl-copy --type image/png < "$capture"
notify-send "Screenshot saved" "$capture"
