#!/usr/bin/env bash
set -e

DOTFILES_REPO="https://github.com/yourusername/dotfiles"
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

# ── Paru ─────────────────────────────────────────────────────────────────────

if ! command -v paru &>/dev/null; then
    info "Installing paru..."
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    pushd /tmp/paru
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/paru
    success "paru installed"
else
    info "paru already installed, skipping"
fi

# ── Dotfiles ──────────────────────────────────────────────────────────────────

if [ ! -d "$DOTFILES_DIR" ]; then
    info "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    info "Dotfiles already cloned, pulling latest..."
    git -C "$DOTFILES_DIR" pull
fi

info "Stowing dotfiles..."
cd "$DOTFILES_DIR"

for dir in */; do
    package="${dir%/}"
    info "Stowing $package..."
    stow --restow "$package"
done

success "Dotfiles stowed"

# ── Terminal tools ────────────────────────────────────────────────────────────

info "Installing terminal tools..."
paru -S --needed --noconfirm \
    fish \
    fisher \
    eza \
    bat \
    ripgrep \
    fd \
    fzf \
    zoxide \
    tldr \
    dust \
    duf \
    btop \
    git-delta \
    yazi

success "Terminal tools installed"



# ── Fish ──────────────────────────────────────────────────────────────────────

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

# ─────────────────────────────────────────────────────────────────────────────

success "Bootstrap complete! Restart your terminal or run: exec fish"
