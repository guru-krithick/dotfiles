#!/bin/sh
pactl set-sink-volume @DEFAULT_SINK@ +5%
notify-send -t 1000 "Volume" "$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)"
