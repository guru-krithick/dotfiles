#!/usr/bin/env bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "don't run this as root — it'll sudo when it needs to" >&2
    exit 1
fi

if ! command -v pacman >/dev/null; then
    echo "this script only knows how to set up Arch (or an Arch derivative)" >&2
    exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }

PACMAN_PACKAGES=(
    zsh tmux neovim ghostty yazi git github-cli git-delta stow man-db
    waybar mako rofi swaybg swayidle slurp grim wl-clipboard cliphist
    xwayland-satellite xdg-desktop-portal-hyprland xdg-utils libinput-tools
    greetd greetd-tuigreet seatd
    pipewire-pulse brightnessctl
    fzf fd ripgrep bat eza zoxide jq fastfetch btop duf
    speedtest-cli smartmontools unzip zip wget
    thunar chromium noto-fonts-emoji adw-gtk-theme
)

AUR_PACKAGES=(
    mangowm-git
    maplemono-nf-unhinted
    swaylock-effects-git
    zen-browser-bin
    visual-studio-code-bin
)

if ! command -v yay >/dev/null; then
    log "installing yay"
    sudo pacman -S --needed --noconfirm base-devel git

    build_dir="$(mktemp -d)"
    git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
    (cd "$build_dir/yay" && makepkg -si --noconfirm)
    rm -rf "$build_dir"
else
    log "yay already installed, skipping"
fi

log "installing official packages"
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

log "installing AUR packages"
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "oh-my-zsh already installed, skipping"
else
    log "installing oh-my-zsh"
    RUNZSH=no KEEP_ZSHRC=yes sh -c \
        "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

clone_if_missing() {
    local repo="$1" dest="$2"
    [[ -d "$dest" ]] || git clone --depth 1 "$repo" "$dest"
}

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

log "fetching zsh plugins (autosuggestions, syntax-highlighting, completions)"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/zsh-users/zsh-completions.git \
    "$ZSH_CUSTOM/plugins/zsh-completions"

log "fetching tpm"
clone_if_missing https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

log "symlinking dotfiles into \$HOME"
stow -v -R -d "$(dirname "$DOTFILES_DIR")" -t "$HOME" "$(basename "$DOTFILES_DIR")"

if [[ "$SHELL" != *"/zsh" ]]; then
    log "switching default shell to zsh"
    chsh -s "$(command -v zsh)"
fi

log "done. log out and back in (or reboot) to land in mango with everything wired up."
echo "first time in tmux, press <prefix> + I to have tpm pull down the plugins."
