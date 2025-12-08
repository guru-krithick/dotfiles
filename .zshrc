# Auto-start Sway on tty1
[[ -z "$NO_SWAY" && "$(tty)" = "/dev/tty1" ]] && exec sway --unsupported-gpu && exec sway reload

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# ZSH CONFIG
# This is oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
export TZ="Asia/Kolkata"
ZSH_THEME=robbyrussell

# Plugins
plugins=(
  aliases
  alias-finder
  command-not-found
  copybuffer
  dirhistory
  docker
  docker-compose
  extract
  fzf
  gh
  git
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

# Load Oh My Zsh
fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
autoload -U compinit && compinit
source "$ZSH/oh-my-zsh.sh"

# Environment Variables
export EDITOR="code"
export BROWSER="vivaldi"

# Dynamic path setup
typeset -U path

for dir in \
    "$HOME/.local/bin" \
    "$HOME/bin" \
    "$HOME/go/bin" \
    "$HOME/.local/share/pnpm" \
    "$HOME/.npm-global/bin" \
    "$HOME/.yarn/bin" \
    "$HOME/.cargo/bin" \
    "$HOME/.pyenv/bin" \
    "$HOME/.rbenv/bin" \
    "/usr/local/bin" \
    "/usr/bin" \
    "/bin" \
    "/usr/lib/jvm/java-17-openjdk/bin:$PATH" \
    "/usr/local/sbin" \
    "/usr/sbin" \
    "/sbin" \
    "/opt/apache-maven-3.9.6/bin:$PATH" \
    "/opt/docker/bin"; do
    
    [[ -d "$dir" ]] && path+=("$dir")
done
# Functions 

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

# Aliases
# GENERAL Aliases
alias python='python3'
alias c='clear'
alias pip='pip3'
alias speedtest='speedtest-cli'
alias btop='btop --force-utf'
alias tmux='tmux -u'
alias e='nvim .'

alias mountde='~/Scripts/mount-scripts/mount_drives.sh'
alias unmountde='~/Scripts/mount-scripts/unmount_drives.sh'

# LIST Aliases
if command -v eza > /dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias la='eza -la --icons --group-directories-first --git'
  alias l='eza -l --icons --group-directories-first'
  alias tree='eza --tree --icons'
  alias ltree='eza --tree --long --icons'
else
  alias ls='ls --color=auto --group-directories-first'
  alias la='ls -la --color=auto'
  alias l='ls -l --color=auto'
fi

# GREP Aliases
if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
  alias fgrep='rg -F'
  alias egrep='rg'
else
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# CAT Aliases
if command -v bat >/dev/null 2>&1; then
  alias cat='bat --paging=never'
  alias catp='bat'
else 
  alias bat='cat'
fi

# IP Aliases
alias myip="ip -4 addr show | awk '/inet/ {print \$2}' | cut -d/ -f1"
alias localip="ip route get 1.1.1.1 | awk '{print \$7}'"
alias publicip='curl -s ifconfig.me'
alias ports='ss -tulwn'

# CONFIG FILES
alias zshconfig='nvim ~/.zshrc'
alias ghosttyconfig='nvim ~/.config/ghostty/config'
alias nvimconfig='nvim ~/.config/nvim/'
alias swayconfig='nvim ~/.config/sway/config'
alias dotfiles='nvim ~/.config'
alias reload='source ~/.zshrc'

# HTTP Server Function
serve(){
  port=${1:-8000}
  python3 -m http.server "$port" && echo "HTTP server is running on http://localhost:$port" || {
    echo "Failed to start HTTP server on port $port"
    return 1
  }
}

# ZSH HISTORY CONFIGURATION
HISTFILE=~/.zsh_history
HISTSIZE=$(( $(free -m | awk '/Mem:/ {print $2}') > 4096 ? 100000 : 50000 ))
SAVEHIST=$HISTSIZE

# ZSH OPTIONS
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

# Load additional configurations if they exist
[[ -r ~/.zsh_local ]] && source ~/.zsh_local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

# pnpm
export PNPM_HOME="/home/guru/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="/usr/lib/jvm/java-17-openjdk/bin:$PATH"

export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

