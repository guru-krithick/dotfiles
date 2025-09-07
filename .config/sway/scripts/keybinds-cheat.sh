#!/bin/bash
# Sway Keybinds Cheat Sheet
# Save this as ~/.config/sway/scripts/keybinds-cheat.sh
# Make it executable: chmod +x ~/.config/sway/scripts/keybinds-cheat.sh

# Create the keybinds data
keybinds=(
    "🚀 APPLICATIONS"
    "Super + T|Open Terminal (foot)"
    "Super + Shift + W|VS Code Editor"
    "Super + Shift + X|Vivaldi Browser"
    "Super + Shift + F|Firefox Browser"
    "Super + Shift + B|Chrome Browser"
    "Super + Shift + N|Neovim (in terminal)"
    "Super + Shift + R|Ranger File Manager"
    "Super + Shift + E|Dolphin GUI File Manager"
    ""
    "🔍 LAUNCHERS"
    "Super + D|Application Launcher (drun)"
    "Super + Shift + D|Run Command Launcher"
    "Super + Tab|Window Switcher"
    ""
    "🪟 WINDOW MANAGEMENT"
    "Super + Q|Close Window"
    "Super + F|Toggle Fullscreen"
    "Super + Space|Toggle Focus (Tiled/Float)"
    "Super + Shift + Space|Toggle Floating"
    "Super + A|Focus Parent Container"
    ""
    "🧭 NAVIGATION (Vim Keys)"
    "Super + H/J/K/L|Focus Left/Down/Up/Right"
    "Super + Shift + H/J/K/L|Move Window Left/Down/Up/Right"
    "Super + Arrows|Focus Direction (Arrow Keys)"
    "Super + Shift + Arrows|Move Window (Arrow Keys)"
    ""
    "💼 WORKSPACES"
    "Super + 1-9,0|Switch to Workspace 1-10"
    "Super + Shift + 1-9,0|Move Window to Workspace 1-10"
    ""
    "📐 LAYOUTS"
    "Super + B|Split Horizontal"
    "Super + V|Split Vertical"
    "Super + S|Stacking Layout"
    "Super + W|Tabbed Layout"
    "Super + E|Toggle Split Layout"
    "Super + R|Resize Mode"
    ""
    "🎬 SCREENSHOTS & RECORDING"
    "Print|Full Screen Screenshot"
    "Super + Shift + S|Area Selection Screenshot"
    "Super + Shift + Print|Start Screen Recording"
    ""
    "🔊 MEDIA CONTROLS"
    "Volume Up/Down|Adjust Volume ±5%"
    "Volume Mute|Toggle Audio Mute"
    "Brightness Up/Down|Adjust Screen Brightness ±5%"
    ""
    "📋 CLIPBOARD"
    "Super + Shift + V|Clipboard History"
    "Super + Shift + Del|Delete Clipboard Item"
    "Super + Ctrl + Del|Clear All Clipboard History"
    ""
    "🔧 SCRATCHPAD"
    "Super + Shift + Minus|Send to Scratchpad"
    "Super + Minus|Show/Hide Scratchpad"
    ""
    "⚙️ SYSTEM"
    "Super + C|Toggle Caffeine (Prevent Sleep)"
    "Super + Shift + C|Reload Sway Config"
    "Super + Escape|Power Menu"
    "Super + Ctrl + L|Lock & Suspend"
    "Super + Ctrl + U|Shutdown"
    ""
    "🎯 RESIZE MODE"
    "H/J/K/L or Arrows|Resize Window"
    "Enter/Escape|Exit Resize Mode"
)

# Function to display the cheat sheet using rofi
show_cheatsheet() {
    local formatted_output=""

    for line in "${keybinds[@]}"; do
        if [[ "$line" == "" ]]; then
            formatted_output+="\n"
        elif [[ "$line" =~ ^[🚀🔍🪟🧭💼📐🎬🔊📋🔧⚙️🎯] ]]; then
            # Category headers
            formatted_output+="\n<span weight='bold' size='large' foreground='#7aa2f7'>$line</span>\n"
        else
            # Regular keybinds
            IFS='|' read -r key desc <<<"$line"
            formatted_output+="<span foreground='#bb9af7' weight='bold'>$key</span>  <span foreground='#c0caf5'>$desc</span>\n"
        fi
    done

    echo -e "$formatted_output" | rofi \
        -dmenu \
        -markup-rows \
        -i \
        -p "󰌌 Sway Keybinds" \
        -theme-str 'window { width: 60%; height: 70%; }' \
        -theme-str 'listview { lines: 25; }' \
        -theme-str 'element { padding: 8px; }' \
        -theme-str 'element-text { background-color: inherit; text-color: inherit; }' \
        -no-custom \
        -format 'd' >/dev/null
}

# Alternative function for wofi (if you prefer)
show_cheatsheet_wofi() {
    local formatted_output=""

    for line in "${keybinds[@]}"; do
        if [[ "$line" == "" ]]; then
            formatted_output+="\n"
        elif [[ "$line" =~ ^[🚀🔍🪟🧭💼📐🎬🔊📋🔧⚙️🎯] ]]; then
            formatted_output+="$line\n"
        else
            IFS='|' read -r key desc <<<"$line"
            formatted_output+="$key → $desc\n"
        fi
    done

    echo -e "$formatted_output" | wofi \
        --dmenu \
        --prompt "Sway Keybinds" \
        --width 800 \
        --height 600 \
        --allow-markup \
        --no-actions >/dev/null
}

# Main execution
case "${1:-rofi}" in
"rofi")
    show_cheatsheet
    ;;
"wofi")
    show_cheatsheet_wofi
    ;;
*)
    echo "Usage: $0 [rofi|wofi]"
    echo "Default: rofi"
    exit 1
    ;;
esac
