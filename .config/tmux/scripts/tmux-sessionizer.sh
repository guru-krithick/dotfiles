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

GIT_ONLY=false
USE_ZOXIDE=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --git-only)
        GIT_ONLY=true
        shift
        ;;
    --zoxide)
        USE_ZOXIDE=true
        shift
        ;;
    *)
        selected=$1
        shift
        ;;
    esac
done

if [[ -z "$selected" ]]; then
    if [[ "$GIT_ONLY" == true ]]; then
        projects=$(find "${EXISTING_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d -exec test -d {}/.git \; -print 2>/dev/null | sort -u)
    else
        projects=$(find "${EXISTING_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -u)
    fi

    if [[ "$USE_ZOXIDE" == true ]] && command -v zoxide >/dev/null 2>&1; then
        zoxide_dirs=$(zoxide query -l 2>/dev/null | grep -E "^($(
            IFS='|'
            echo "${EXISTING_DIRS[*]}"
        ))" | head -10)
        projects=$(echo -e "$projects\n$zoxide_dirs" | sort -u)
    fi

    selected=$(echo "$projects" |
        fzf --height 40% --reverse --border --prompt "  Project: " \
            --preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls -la {}' \
            --preview-window right:50% \
            --bind 'ctrl-x:execute(tmux kill-session -t $(basename {} | tr "." "_") 2>/dev/null)+reload(echo "$projects")' \
            --header 'CTRL-X: kill session')
fi

[[ -z "$selected" ]] && exit 0

parent_dir=$(basename "$(dirname "$selected")")
base_name=$(basename "$selected" | tr '.' '_')
selected_name="${parent_dir}_${base_name}"

tmux_running=$(pgrep tmux)

auto_setup_project() {
    local project_dir="$1"
    local session_name="$2"

    # Check for custom .tmux file first
    if [[ -f "$project_dir/.tmux" ]]; then
        source "$project_dir/.tmux"
        return
    fi

    # Auto-detect project type and setup
    cd "$project_dir"

    # Node.js/JavaScript/TypeScript projects
    if [[ -f "package.json" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "server" -c "$project_dir"

        # Check for common dev commands
        if grep -q '"dev"' package.json 2>/dev/null; then
            tmux send-keys -t "$session_name:2" "npm run dev" C-m
        elif grep -q '"start"' package.json 2>/dev/null; then
            tmux send-keys -t "$session_name:2" "npm start" C-m
        fi

        tmux new-window -t "$session_name:3" -n "terminal" -c "$project_dir"
        tmux select-window -t "$session_name:1"
        return
    fi

    # Python projects
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "terminal" -c "$project_dir"

        # Auto-activate venv if exists
        for venv_dir in venv .venv env .env; do
            if [[ -d "$project_dir/$venv_dir" ]]; then
                tmux send-keys -t "$session_name:2" "source $venv_dir/bin/activate" C-m
                break
            fi
        done

        tmux select-window -t "$session_name:1"
        return
    fi

    # Go projects
    if [[ -f "go.mod" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "run" -c "$project_dir"
        tmux send-keys -t "$session_name:2" "go run ."
        tmux new-window -t "$session_name:3" -n "tests" -c "$project_dir"
        tmux select-window -t "$session_name:1"
        return
    fi

    # Rust projects
    if [[ -f "Cargo.toml" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "run" -c "$project_dir"
        tmux send-keys -t "$session_name:2" "cargo run"
        tmux new-window -t "$session_name:3" -n "tests" -c "$project_dir"
        tmux select-window -t "$session_name:1"
        return
    fi

    # Java/Maven projects
    if [[ -f "pom.xml" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "maven" -c "$project_dir"
        tmux new-window -t "$session_name:3" -n "terminal" -c "$project_dir"
        tmux select-window -t "$session_name:1"
        return
    fi

    # Docker Compose projects
    if [[ -f "docker-compose.yml" ]] || [[ -f "docker-compose.yaml" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "docker" -c "$project_dir"
        tmux send-keys -t "$session_name:2" "docker-compose up"
        tmux new-window -t "$session_name:3" -n "logs" -c "$project_dir"
        tmux select-window -t "$session_name:1"
        return
    fi

    # Makefile projects
    if [[ -f "Makefile" ]]; then
        tmux rename-window -t "$session_name:1" "editor"
        tmux new-window -t "$session_name:2" -n "make" -c "$project_dir"
        tmux new-window -t "$session_name:3" -n "terminal" -c "$project_dir"
        tmux select-window -t "$session_name:1"
        return
    fi

    # Default: just 2 windows
    tmux rename-window -t "$session_name:1" "editor"
    tmux new-window -t "$session_name:2" -n "terminal" -c "$project_dir"
    tmux select-window -t "$session_name:1"
}

if [[ -z "$TMUX" ]] && [[ -z "$tmux_running" ]]; then
    tmux new-session -s "$selected_name" -c "$selected"
    exit 0
fi

if ! tmux has-session -t="$selected_name" 2>/dev/null; then
    tmux new-session -ds "$selected_name" -c "$selected"
    auto_setup_project "$selected" "$selected_name"
fi

if [[ -z "$TMUX" ]]; then
    tmux attach-session -t "$selected_name"
else
    tmux switch-client -t "$selected_name"
fi
