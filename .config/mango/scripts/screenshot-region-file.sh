#!/bin/sh
set -eu

region=$(slurp) || exit 0
[ -n "$region" ] || exit 0
PICS="${XDG_PICTURES_DIR:-$HOME/Pictures}"
mkdir -p "$PICS"
capture=$(mktemp "$PICS/screenshot-$(date +%Y%m%d-%H%M%S)-XXXXXX.png")
if ! grim -g "$region" "$capture"; then
    rm -f "$capture"
    exit 1
fi
wl-copy --type image/png < "$capture"
notify-send "Screenshot saved" "$capture"
