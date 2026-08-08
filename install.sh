#!/usr/bin/env bash
#
# Provision an Arch machine from this dotfiles repo: packages, out-of-repo
# toolchains, plugin managers, then stow the configs into $HOME.
#
# Assumes the base install already handles the login manager, networking,
# graphics drivers and microcode. None of that is touched here.
#
# Safe to re-run; every step is guarded and skips work already done.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

readonly PACMAN_PACKAGES=(
    # shell and prompt
    zsh starship tmux

    # editors and terminals
    neovim ghostty kitty zed

    # cli toolbelt
    git github-cli git-delta stow man-db yazi
    fzf fd ripgrep bat eza zoxide jq fastfetch btop duf
    speedtest-cli smartmontools unzip zip wget

    # nvim-treesitter's main branch shells out to the tree-sitter CLI to
    # compile parsers; the old master branch did this in-process. Without it
    # every parser build fails with ENOENT.
    tree-sitter-cli

    # mason installs the LSPs and formatters, but the language runtimes they
    # execute under have to come from the system
    nodejs npm pnpm rustup go jdk21-openjdk

    # wayland session: compositor bits, bar, launcher, screenshots
    waybar mako rofi swaybg swayidle
    slurp grim wl-clipboard cliphist
    # swayidle's timeout chain calls wlopm to blank the outputs, and
    # Super+Shift+R records through wf-recorder
    wlopm wf-recorder
    xwayland-satellite xorg-xwayland
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-utils
    libinput-tools brightnessctl

    # audio
    pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber
    pavucontrol libpulse sof-firmware

    # theming — GTK_THEME in .zshrc and the gsettings calls in mango's
    # exec-once block name these by string, so a missing one degrades to an
    # unstyled session rather than an error
    materia-gtk-theme adw-gtk-theme papirus-icon-theme
    lxappearance qt5ct qt6ct
    noto-fonts-emoji

    # file manager and thumbnailers (tumbler backs thunar's previews; yazi
    # reads poppler and ffmpegthumbnailer for pdf and video thumbs)
    thunar tumbler ffmpegthumbnailer poppler-glib

    # media and documents
    mpv zathura zathura-pdf-mupdf okular foliate libreoffice-fresh
    gst-libav gst-plugin-pipewire

    # browsers
    chromium

    # secrets — the only daemon installed here; git and the browsers expect a
    # running secret service for stored credentials
    gnome-keyring
)

readonly AUR_PACKAGES=(
    mangowm-git
    maplemono-nf-unhinted
    swaylock-effects-git
    zen-browser-bin
    visual-studio-code-bin
    obsidian-bin
)

readonly NPM_GLOBALS=(
    vercel
    @juliusbrussee/caveman-code
)

readonly NPM_PREFIX="$HOME/.npm-global"

# --- helpers ----------------------------------------------------------------

log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
skip() { printf '    \033[2m%s already present, skipping\033[0m\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

clone_if_missing() {
    local repo="$1" dest="$2"
    [[ -d "$dest" ]] && return 0
    git clone --depth 1 "$repo" "$dest"
}

# --- phases -----------------------------------------------------------------

check_preconditions() {
    [[ $EUID -ne 0 ]] || die "don't run this as root — it'll sudo when it needs to"
    have pacman || die "this script only knows how to set up Arch (or an Arch derivative)"
}

install_yay() {
    if have yay; then
        skip yay
        return
    fi

    log "installing yay"
    sudo pacman -S --needed --noconfirm base-devel git

    local build_dir
    build_dir="$(mktemp -d)"
    trap 'rm -rf "$build_dir"' RETURN

    git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
    (cd "$build_dir/yay" && makepkg -si --noconfirm)
}

install_packages() {
    log "installing official packages"
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

    log "installing AUR packages"
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

# Toolchains with no Arch package that the shell config still expects on PATH.
# Guards test the binary rather than its install directory, so a half-finished
# install is retried instead of skipped.
install_toolchains() {
    log "installing out-of-repo toolchains"

    if rustup toolchain list 2>/dev/null | grep -q .; then
        skip "rust toolchain"
    else
        rustup default stable
    fi

    if have bun; then
        skip bun
    else
        curl -fsSL https://bun.sh/install | bash
    fi

    if have uv; then
        skip uv
    else
        curl -fsSL https://astral.sh/uv/install.sh | sh
    fi

    # .zshrc aliases cc to claude
    if have claude; then
        skip "claude code"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    log "installing npm globals"
    npm install -g --prefix "$NPM_PREFIX" "${NPM_GLOBALS[@]}"
}

# antidote replaced oh-my-zsh. It reads .zsh_plugins.txt (stowed below) and
# compiles it to .zsh_plugins.zsh on first shell start, so nothing here needs
# to fetch individual plugin repos.
install_plugin_managers() {
    log "fetching antidote"
    clone_if_missing https://github.com/mattmc3/antidote.git "$HOME/.antidote"

    log "fetching tpm"
    clone_if_missing https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
}

link_dotfiles() {
    log "symlinking dotfiles into \$HOME"
    stow -v -R -d "$(dirname "$DOTFILES_DIR")" -t "$HOME" "$(basename "$DOTFILES_DIR")"
}

# powerboost writes the GPU frequency floor and vm.swappiness, both root-only.
# It is bound to a key and to a waybar click, neither of which has a tty for
# sudo to prompt on, so without this rule those two writes fail silently and
# only the power-profiles-daemon half of the toggle takes effect.
install_powerboost_sudoers() {
    local rule=/etc/sudoers.d/powerboost

    if sudo test -f "$rule"; then
        skip "powerboost sudoers rule"
        return
    fi

    log "installing powerboost sudoers rule"
    # Scoped to these two exact commands, nothing else.
    sudo tee "$rule" >/dev/null <<EOF
$USER ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/drm/card[0-9]/gt_min_freq_mhz
$USER ALL=(root) NOPASSWD: /usr/bin/sysctl -q -w vm.swappiness=[0-9]*
EOF
    sudo chmod 0440 "$rule"
    sudo visudo -cf "$rule"
}

set_login_shell() {
    if [[ "$SHELL" == *"/zsh" ]]; then
        skip "zsh as login shell"
        return
    fi

    log "switching default shell to zsh"
    chsh -s "$(command -v zsh)"
}

print_next_steps() {
    log "done"
    cat <<'EOF'
    log out and back in (or reboot) to land in mango with everything wired up.
    first time in tmux, press <prefix> + I to have tpm pull down the plugins.
EOF
}

# --- entrypoint -------------------------------------------------------------

main() {
    check_preconditions
    install_yay
    install_packages
    install_toolchains
    install_plugin_managers
    link_dotfiles
    install_powerboost_sudoers
    set_login_shell
    print_next_steps
}

main "$@"
