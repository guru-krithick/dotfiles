#!/bin/sh
pactl set-sink-mute @DEFAULT_SINK@ toggle
notify-send -t 1000 "Volume" "$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes && echo Muted || echo Unmuted)"
