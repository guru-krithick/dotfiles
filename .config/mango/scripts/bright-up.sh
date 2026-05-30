#!/bin/sh
brightnessctl set +2%
notify-send -t 1000 "Brightness" "$(brightnessctl -m | cut -d',' -f4)"
