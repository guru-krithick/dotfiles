[[ -z "$NO_MANGO" && "$TTY" == /dev/tty1 ]] && exec mango

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Extra completions need to be on fpath before OMZ starts.
fpath=("${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src" $fpath)
plugins=(git extract sudo zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

export TZ="Asia/Kolkata"
export BROWSER="zen-browser"
export EDITOR="code --wait"
export _JAVA_AWT_WM_NONREPARENTING=1
export GTK_THEME=Materia-dark
export GTK_USE_PORTAL=1
export BAT_THEME="base16-256"

export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"

path=(
    $PNPM_HOME
    $BUN_INSTALL/bin
    $HOME/.local/bin
    $HOME/go/bin
    $HOME/.npm-global/bin
    $HOME/.cargo/bin
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
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {}'"
source <(fzf --zsh)

# OMZ handles the usual history and completion options.
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt PUSHD_SILENT NUMERIC_GLOB_SORT INTERACTIVE_COMMENTS
setopt NO_BEEP NO_FLOW_CONTROL

eval "$(zoxide init zsh --cmd cd)"
alias z=cd
alias zi=cdi

serve() {
    python3 -m http.server "${1:-8000}"
}

# Ctrl-R: history, Ctrl-T: files, Alt-C: directories (fzf).
# Ctrl-F accepts a suggestion; Alt-Right accepts one word.
bindkey '^F' autosuggest-accept
bindkey '^[[1;3C' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search
bindkey '^X^U' undo
bindkey '^X^R' redo
# Edit a long command in nvim with Ctrl-X Ctrl-E.
autoload -Uz edit-command-line
zle -N edit-command-line
zstyle :zle:edit-command-line editor nvim
bindkey '^X^E' edit-command-line

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

alias zshconfig='nvim ~/.zshrc'
alias ghosttyconfig='nvim ~/.config/ghostty/config'
alias nvimconfig='nvim ~/.config/nvim/'
alias mangoconfig='nvim ~/.config/mango/config.conf'
alias dotfiles='nvim ~/dotfiles'
alias reload='exec zsh'

if [[ -r ~/.zsh_local ]]; then
    source ~/.zsh_local
fi
