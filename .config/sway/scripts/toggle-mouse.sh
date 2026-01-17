#!/bin/bash

STATE_FILE="/tmp/sway-mouse-disabled"

if [ -f "$STATE_FILE" ]; then
    swaymsg "input type:touchpad events enabled"
    swaymsg "input type:pointer events enabled"
    swaymsg "seat seat0 hide_cursor 0"
    rm "$STATE_FILE"
    notify-send -t 1500 "Mouse enabled" "Normal mode"
else
    swaymsg "input type:touchpad events disabled"
    swaymsg "input type:pointer events disabled"
    swaymsg "seat seat0 hide_cursor 1"
    touch "$STATE_FILE"
    notify-send -t 1500 "Mouse disabled" "Keyboard-only mode"
fi
