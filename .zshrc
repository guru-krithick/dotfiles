# Auto-start Sway on tty1
[[ -z "$NO_SWAY" && "$(tty)" = "/dev/tty1" ]] && exec sway --unsupported-gpu && exec sway reload

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_COMPDUMP="$HOME/.zcompdump"
export TZ="Asia/Kolkata"
export EDITOR="code"
export BROWSER="zen-browser"

# pnpm
export PNPM_HOME="/home/guru/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Java
export PATH="/usr/lib/jvm/java-17-openjdk/bin:$PATH"

# Android SDK
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.pyenv/bin:$PATH"
export PATH="/opt/apache-maven-3.9.6/bin:$PATH"
export PATH="/opt/docker/bin:$PATH"

# Conda
export CONDA_HOME="$HOME/miniconda3"
export PATH="$CONDA_HOME/bin:$PATH"

# FZF Ultra Dark Theme
export FZF_DEFAULT_OPTS="
  --height 85%
  --bind ctrl-u:preview-up,ctrl-d:preview-down
  --bind ctrl-/:toggle-preview
  --border rounded
  --color=bg:#0a0a0a,bg+:#1c1c1c,fg:#b0b0b0,fg+:#d0d0d0
  --color=spinner:#6a8ac0,hl:#b06a6e,hl+:#b06a6e
  --color=header:#6a8ac0,info:#8a8a8a,prompt:#6a8ac0
  --color=pointer:#6a8ac0,marker:#8aaa6a
  --prompt '❯ '
  --pointer '▶'
  --marker '✓'
"

export BAT_THEME="base16-256"

# ============================================================================
# OH-MY-ZSH CONFIGURATION
# ============================================================================
ZSH_THEME=robbyrussell

plugins=(
  alias-finder
  command-not-found
  copybuffer
  dirhistory
  docker
  docker-compose
  extract
  fzf
  gh
  history
  jsontools
  npm
  nvm
  pip
  postgres
  python
  react-native
  systemd
  tmux
  vscode
  web-search
  yarn
  z
  zoxide
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
)

# Load completions
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src

# Load Oh My Zsh
source "$ZSH/oh-my-zsh.sh"

# bun completions
[ -s "/home/guru/.bun/_bun" ] && source "/home/guru/.bun/_bun"

# Conda initialize
if [ -f "/home/guru/miniconda3/etc/profile.d/conda.sh" ]; then
    . "/home/guru/miniconda3/etc/profile.d/conda.sh"
else
    export PATH="/home/guru/miniconda3/bin:$PATH"
fi

# ============================================================================
# ZSH OPTIONS
# ============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=$(( $(free -m | awk '/Mem:/ {print $2}') > 4096 ? 100000 : 50000 ))
SAVEHIST=$HISTSIZE

# History options
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Directory options
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CDABLE_VARS

# Completion options
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt PATH_DIRS
setopt AUTO_MENU
setopt AUTO_LIST
setopt AUTO_PARAM_SLASH
setopt COMPLETE_ALIASES

# Globbing options
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt NUMERIC_GLOB_SORT

# General options
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt LONG_LIST_JOBS
setopt AUTO_RESUME
setopt NOTIFY
setopt NO_BEEP
setopt NO_FLOW_CONTROL

# ============================================================================
# FUNCTIONS
# ============================================================================
# Python virtual environment auto-activation
_venv_auto_activate() {
  if [[ -z "$VIRTUAL_ENV" ]]; then
    for candidate in .venv venv .env; do
      if [[ -d "./$candidate" ]]; then
        source "./$candidate/bin/activate"
        break 
      fi
    done
  else
    parentdir="$(dirname "$VIRTUAL_ENV")"
    if [[ "$PWD"/ != "$parentdir"/* ]]; then
      deactivate
    fi
  fi
}

# Hook into cd command
function cd(){
  builtin cd "$@"
  _venv_auto_activate
}

# Hook into zoxide (z command)
if command -v zoxide >/dev/null 2>&1; then
  function z() {
    __zoxide_z "$@"
    _venv_auto_activate
  }
fi

# Also hook into chpwd for any directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd _venv_auto_activate

# HTTP Server Function
serve(){
  port=${1:-8000}
  python3 -m http.server "$port" && echo "HTTP server is running on http://localhost:$port" || {
    echo "Failed to start HTTP server on port $port"
    return 1
  }
}

vf() {
  local file
  file=$(
        git ls-files 2>/dev/null |
        fzf --preview 'bat --color=always --style=numbers {}' --preview-window=right:60%) &&
        nvim "$file"
}

gl() {
    git log --oneline --color=always |
    fzf --ansi --preview 'git show --color {1}' --preview-window=right:60%
}

extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.zip) unzip "$1" ;;
      *.Z) uncompress "$1" ;;
      *.7z) 7z x "$1" ;;
      *) echo "'$1' cannot be extracted" ;;
    esac
  fi
}

# Tmux Sessionizer (Ctrl+f to trigger)
bindkey -s '^f' '^u~/.config/tmux/scripts/tmux-sessionizer.sh\n'

# ============================================================================
# ALIASES
# ============================================================================
alias c='clear'
alias e='nvim'
alias y='yazi'

alias python='python3'
alias pip='pip3'

alias speedtest='speedtest-cli'

alias btop='btop --force-utf'
alias tmux='tmux -u'

if command -v eza > /dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias la='eza -la --icons --group-directories-first --git'
  alias l='eza -l --icons --group-directories-first'
  alias ltree='eza --tree --icons -a'
else
  alias ls='ls --color=auto --group-directories-first'
  alias la='ls -la --color=auto'
  alias l='ls -l --color=auto'
fi

if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
  alias fgrep='rg -F'
  alias egrep='rg'
else
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias catp='bat'
else 
  alias bat='cat'
fi

alias myip="ip -4 addr show | awk '/inet/ {print \$2}' | cut -d/ -f1"
alias localip="ip route get 1.1.1.1 | awk '{print \$7}'"
alias publicip='curl -s ifconfig.me'
alias ports='ss -tulwn'

alias mountde='~/Scripts/mount-scripts/mount_drives.sh'
alias unmountde='~/Scripts/mount-scripts/unmount_drives.sh'

# CONFIG FILES
alias zshconfig='nvim ~/.zshrc'
alias ghosttyconfig='nvim ~/.config/ghostty/config'
alias nvimconfig='nvim ~/.config/nvim/'
alias swayconfig='nvim ~/.config/sway/config'
alias dotfiles='nvim ~/dotfiles'
alias reload='source ~/.zshrc'

# Load local configurations if they exist
[[ -r ~/.zsh_local ]] && source ~/.zsh_local

# Ensure clean exit
true
