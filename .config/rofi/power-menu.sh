#!/bin/bash


options="󰌾 Lock\n󰒲 Suspend\n󰗼 Logout\n󰒪 Battery\n󰜉 Reboot\n Shutdown"

selected=$(echo -e "$options" | rofi -dmenu -theme ~/.config/rofi/power.rasi -p "" -selected-row 0)

case "$selected" in
    *"Lock"*)
        swaylock -f -C ~/.config/swaylock/config
        ;;
    *"Suspend"*)
        swaylock -f -C ~/.config/swaylock/config && systemctl suspend
        ;;
    *"Logout"*)
        swaymsg exit
        ;;
    *"Battery"*)
        if [[ -f "/tmp/battery-saver-enabled" ]]; then
            rm /tmp/battery-saver-enabled
            brightnessctl set 100%
            powerprofilesctl set balanced 2>/dev/null || true
            notify-send "󰁹 Battery Saver" "Disabled"
        else
            touch /tmp/battery-saver-enabled
            brightnessctl set 40%
            powerprofilesctl set power-saver 2>/dev/null || true
            notify-send "󰁾 Battery Saver" "Enabled"
        fi
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Shutdown"*)
        systemctl poweroff
        ;;
esac
