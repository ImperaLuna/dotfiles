#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}==>${NC} $1"; }
success() { echo -e "${GREEN}==>${NC} $1"; }
error()   { echo -e "${RED}==>${NC} $1"; exit 1; }

# ── Prerequisites ─────────────────────────────────────────────────────────────

if ! command -v yay &>/dev/null; then
    error "yay is not installed. Run terminal_setup.sh first."
fi

if ! command -v stow &>/dev/null; then
    error "stow is not installed. Run terminal_setup.sh first."
fi

# ── Fonts ─────────────────────────────────────────────────────────────────────

info "Installing fonts..."
yay -S --needed --noconfirm \
    ttf-jetbrains-mono-nerd \
    ttf-material-symbols-variable
fc-cache -f
success "Fonts installed"

# ── Quickshell ────────────────────────────────────────────────────────────────

info "Installing quickshell..."
yay -S --needed --noconfirm quickshell-git
success "quickshell installed"

# ── Stow helpers ──────────────────────────────────────────────────────────────

stow_clean() {
    local pkg="$1"      # e.g. "hyprland"
    local cfg_dir="$2"  # e.g. "$HOME/.config/hypr"

    info "Stowing $pkg..."

    # Remove existing dir/symlink so stow starts clean
    if [ -L "$cfg_dir" ]; then
        rm "$cfg_dir"
    elif [ -d "$cfg_dir" ]; then
        rm -rf "$cfg_dir"
    fi

    stow --target ~ --restow "$pkg"
    success "$pkg stowed"
}

cd "$DOTFILES_DIR/desktop"

stow_clean "hyprland"   "$HOME/.config/hypr"
stow_clean "quickshell" "$HOME/.config/quickshell"

# ─────────────────────────────────────────────────────────────────────────────

success "Desktop setup complete!"
