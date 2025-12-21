#!/usr/bin/env bash
SEARCH_DIRS=(
    ~/projects
    ~/frontend
    ~/backend
    ~/oss
    ~/learn
    ~/dotfiles
    ~/dsa
    ~/java-class
)

EXISTING_DIRS=()
for dir in "${SEARCH_DIRS[@]}"; do
    expanded_dir="${dir/#\~/$HOME}"
    [[ -d "$expanded_dir" ]] && EXISTING_DIRS+=("$expanded_dir")
done

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find "${EXISTING_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | \
        sort -u | \
        fzf --height 40% --reverse --border --prompt "  Project: " \
            --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}' \
            --preview-window right:50%)
fi


[[ -z "$selected" ]] && exit 0

selected_name=$(basename "$selected" | tr '.' '_')

tmux_running=$(pgrep tmux)

if [[ -z "$TMUX" ]] && [[ -z "$tmux_running" ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
fi

if [[ -z "$TMUX" ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
