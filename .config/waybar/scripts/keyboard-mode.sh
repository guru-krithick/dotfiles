#!/bin/bash

if [[ -f "/tmp/sway-mouse-disabled" ]]; then
    echo '{"text": "󰌌", "tooltip": "Keyboard-only mode\nMod+F10 to toggle", "class": "active"}'
else
    echo '{"text": "󰍽", "tooltip": "Normal mode\nMod+F10 to toggle", "class": "inactive"}'
fi
