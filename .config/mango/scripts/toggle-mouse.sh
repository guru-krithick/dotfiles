#!/bin/sh
# mango has no IPC for input toggling; we disable_trackpad via config reload instead
STATE_FILE="/tmp/mango-mouse-disabled"

if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    notify-send -t 1500 "Mouse enabled" "Normal mode"
else
    touch "$STATE_FILE"
    notify-send -t 1500 "Mouse disabled" "Keyboard-only mode"
fi
