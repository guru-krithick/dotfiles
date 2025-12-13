# Auto-start Sway on tty1
[[ -z "$NO_SWAY" && "$(tty)" = "/dev/tty1" ]] && exec sway --unsupported-gpu && exec sway reload

# Load modular configuration files
[[ -r "$ZDOTDIR/.zsh_exports" ]]   && source "$ZDOTDIR/.zsh_exports"

# Oh-My-Zsh theme (must be set before loading plugins)
ZSH_THEME=robbyrussell

[[ -r "$ZDOTDIR/.zsh_plugins" ]]   && source "$ZDOTDIR/.zsh_plugins"
[[ -r "$ZDOTDIR/.zsh_options" ]]   && source "$ZDOTDIR/.zsh_options"
[[ -r "$ZDOTDIR/.zsh_functions" ]] && source "$ZDOTDIR/.zsh_functions"
[[ -r "$ZDOTDIR/.zsh_aliases" ]]   && source "$ZDOTDIR/.zsh_aliases"

# Load local configurations if they exist
[[ -r ~/.zsh_local ]] && source ~/.zsh_local

# Ensure clean exit
true

