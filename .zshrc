[[ -z "$NO_MANGO" && "$(tty)" == "/dev/tty1" ]] && exec mango

zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

source ${ZDOTDIR:-$HOME}/.antidote/antidote.zsh

if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
    antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi
source ${zsh_plugins}.zsh

eval "$(starship init zsh)"

export TZ="Asia/Kolkata"
export EDITOR="code"
export BROWSER="zen-browser"
export _JAVA_AWT_WM_NONREPARENTING=1
export GTK_THEME=Materia-dark
export GTK_USE_PORTAL=1
export BAT_THEME="base16-256"

export PNPM_HOME="$HOME/.local/share/pnpm"
export ANDROID_HOME="$HOME/Android/Sdk"
export BUN_INSTALL="$HOME/.bun"
export CONDA_HOME="$HOME/miniconda3"

path=(
    $PNPM_HOME
    /usr/lib/jvm/java-17-openjdk/bin
    $ANDROID_HOME/tools
    $ANDROID_HOME/platform-tools
    $BUN_INSTALL/bin
    $HOME/.local/bin
    $HOME/bin
    $HOME/go/bin
    $HOME/.npm-global/bin
    $HOME/.cargo/bin
    $HOME/.pyenv/bin
    /opt/apache-maven-3.9.6/bin
    /opt/docker/bin
    $CONDA_HOME/bin
    $path
)
typeset -U path

export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude .npm --exclude dist --exclude build'
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
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git --exclude node_modules'

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS HIST_VERIFY

setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT CDABLE_VARS
setopt COMPLETE_IN_WORD ALWAYS_TO_END PATH_DIRS AUTO_MENU AUTO_LIST
setopt AUTO_PARAM_SLASH COMPLETE_ALIASES
setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT
setopt INTERACTIVE_COMMENTS LONG_LIST_JOBS AUTO_RESUME NOTIFY
setopt NO_BEEP NO_FLOW_CONTROL

eval "$(zoxide init zsh)"

function cd() {
    if [[ $# -eq 0 ]]; then
        builtin cd ~
    else
        __zoxide_z "$@"
    fi
    _venv_auto_activate
}

_venv_auto_activate() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        local current_dir="$PWD"
        while [[ "$current_dir" != "/" ]]; do
            for candidate in .venv venv .env; do
                if [[ -d "$current_dir/$candidate" ]]; then
                    source "$current_dir/$candidate/bin/activate"
                    return
                fi
            done
            current_dir="$(dirname "$current_dir")"
        done
    else
        local parentdir="$(dirname "$VIRTUAL_ENV")"
        if [[ "$PWD"/ != "$parentdir"/* ]]; then
            deactivate
        fi
    fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _venv_auto_activate

serve() {
    local port=${1:-8000}
    python3 -m http.server "$port" && echo "HTTP server on http://localhost:$port" || {
        echo "Failed to start server on port $port"
        return 1
    }
}

bindkey -s '^f' '^u~/.config/tmux/scripts/tmux-sessionizer.sh\n'

alias -s {js,ts,jsx,tsx,py,json,yaml,yml,toml,md,txt}=nvim
alias -s pdf=zathura
alias -s git="git clone"

alias c='printf "\033[H\033[2J\033[3J"'
alias e='zeditor --new .'
alias n='nvim'
alias y='yazi'
alias t='tmux -u'
alias tmux='tmux -u'
alias speedtest='speedtest-cli'
alias btop='btop --force-utf'
alias cc='claude'
alias oc='opencode'

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias la='eza -la --icons --group-directories-first --git'
    alias l='eza -l --icons --group-directories-first'
    alias ltree='eza --tree --icons -a'
else
    alias ls='ls --color=auto --group-directories-first'
    alias la='ls -la --color=auto'
    alias l='ls -l --color=auto'
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

alias zshconfig='nvim ~/.zshrc'
alias ghosttyconfig='nvim ~/.config/ghostty/config'
alias nvimconfig='nvim ~/.config/nvim/'
alias mangoconfig='nvim ~/.config/mango/config.conf'
alias dotfiles='nvim ~/dotfiles'
alias reload='source ~/.zshrc'

[[ -r ~/.zsh_local ]] && source ~/.zsh_local
