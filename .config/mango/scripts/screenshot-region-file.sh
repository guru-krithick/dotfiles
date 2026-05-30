#!/bin/sh
PICS="${XDG_PICTURES_DIR:-$HOME/Pictures}"
grim -g "$(slurp)" - | tee "$PICS/screenshot-$(date +%Y%m%d-%H%M%S).png" | wl-copy
