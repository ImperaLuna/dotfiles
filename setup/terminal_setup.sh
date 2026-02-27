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

# ── Terminal tools ────────────────────────────────────────────────────────────

info "Installing terminal tools..."
yay -S --needed --noconfirm \
    fish \
    fisher \
    starship \
    eza \
    bat \
    ripgrep \
    fd \
    fzf \
    zoxide \
    tealdeer \
    dust \
    duf \
    btop \
    git-delta \
    yazi \
    tmux \
    neovim \
    lazygit \
    ttf-jetbrains-mono-nerd \
    wl-clipboard

info "Installing yazi dependencies..."
yay -S --needed --noconfirm \
    ffmpeg \
    p7zip \
    poppler \
    jq \
    resvg \
    imagemagick

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
fish --no-config -c "set -ga fish_function_path ~/.config/fish/functions; fisher update"

success "Fisher and plugins installed"

info "Building bat theme cache..."
bat cache --build
success "bat cache built"

# ─────────────────────────────────────────────────────────────────────────────

success "Bootstrap complete! Restart your terminal or run: exec fish"
