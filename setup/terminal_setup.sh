#!/usr/bin/env bash
set -e

DOTFILES_DIR="$HOME/dotfiles"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}==>${NC} $1"; }
error()   { echo -e "${RED}==>${NC} $1"; exit 1; }

# ── Prerequisites ────────────────────────────────────────────────────────────

info "Updating system..."
sudo pacman -Syu --noconfirm

info "Installing base dependencies..."
sudo pacman -S --needed --noconfirm git base-devel stow

# ── Yay ──────────────────────────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v yay &>/dev/null; then
    info "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    pushd /tmp/yay
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/yay
    success "yay installed"
else
    info "yay already installed, skipping"
fi

# ── Dotfiles ──────────────────────────────────────────────────────────────────
STOW_PACKAGES=(fish git starship btop yazi bat eza tmux nvim lazygit)

info "Stowing dotfiles..."
cd "$DOTFILES_DIR/terminal"
for package in "${STOW_PACKAGES[@]}"; do
    info "Stowing $package..."
    stow --target ~ --restow "$package"
done

# ── Fish ──────────────────────────────────────────────────────────────────────

info "Installing fish and shell environment..."
yay -S --needed --noconfirm \
    fish \
    fisher \
    fzf \
    tealdeer \
    starship \
    zoxide \
    git-delta \
    bat \
    eza \
    ripgrep \
    fd

# ── Neovim ────────────────────────────────────────────────────────────────────

info "Installing neovim and dependencies..."
yay -S --needed --noconfirm \
    neovim \
    tree-sitter-cli \
    lazygit

# ── Yazi ──────────────────────────────────────────────────────────────────────

info "Installing yazi and dependencies..."
yay -S --needed --noconfirm \
    yazi \
    ffmpeg \
    7zip \
    poppler \
    jq \
    resvg \
    imagemagick \
    ttf-jetbrains-mono-nerd \
    wl-clipboard

# ── Other tools ───────────────────────────────────────────────────────────────

info "Installing other tools..."
yay -S --needed --noconfirm \
    dust \
    duf \
    btop \
    tmux

success "All tools installed"



# ── Default shell ─────────────────────────────────────────────────────────────

info "Setting fish as default shell..."
FISH_PATH=$(which fish)

if ! grep -q "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

if [ "$SHELL" != "$FISH_PATH" ]; then
    chsh -s "$FISH_PATH"
    success "Default shell changed to fish"
else
    info "Fish is already the default shell"
fi

info "Installing fisher and plugins..."
fish -c "fisher update"

success "Fisher and plugins installed"

info "Building bat theme cache..."
bat cache --build
success "bat cache built"

# ── Tmux plugins (TPM) ────────────────────────────────────────────────────────

info "Installing TPM and tmux plugins..."
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi
tmux new-session -d -s __bootstrap 2>/dev/null || true
~/.config/tmux/plugins/tpm/bin/install_plugins
tmux kill-session -t __bootstrap 2>/dev/null || true
success "Tmux plugins installed"

# ─────────────────────────────────────────────────────────────────────────────

success "Bootstrap complete! Restart your terminal or run: exec fish"
