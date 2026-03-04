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
STOW_PACKAGES=(fish git starship btop yazi bat eza tmux nvim lazygit tealdeer)

collect_stow_targets() {
    local package
    local raw_output
    local terminal_dir="$DOTFILES_DIR/terminal"

    (
        cd "$terminal_dir" || exit 1
        for package in "${STOW_PACKAGES[@]}"; do
            raw_output=$(stow -n -v -R --target ~ "$package" 2>/dev/null || true)
            awk '/^LINK: / {print $2}' <<< "$raw_output"
        done
    ) | sort -u
}

backup_existing_targets() {
    local backup_dir="$HOME/.config/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    local rel_path
    local full_path
    local resolved
    local moved_count=0

    info "Creating backup directory at $backup_dir"
    mkdir -p "$backup_dir"

    while IFS= read -r rel_path; do
        [ -z "$rel_path" ] && continue
        full_path="$HOME/$rel_path"

        if [ ! -e "$full_path" ] && [ ! -L "$full_path" ]; then
            continue
        fi

        if [ -L "$full_path" ]; then
            resolved="$(readlink -f "$full_path" 2>/dev/null || true)"
            if [[ -n "$resolved" && "$resolved" == "$DOTFILES_DIR/"* ]]; then
                continue
            fi
        fi

        mkdir -p "$backup_dir/$(dirname "$rel_path")"
        mv "$full_path" "$backup_dir/$rel_path"
        moved_count=$((moved_count + 1))
    done < <(collect_stow_targets)

    success "Backed up $moved_count path(s) to $backup_dir"
}

remove_existing_targets() {
    local rel_path
    local full_path
    local resolved
    local removed_count=0

    while IFS= read -r rel_path; do
        [ -z "$rel_path" ] && continue
        full_path="$HOME/$rel_path"

        if [ ! -e "$full_path" ] && [ ! -L "$full_path" ]; then
            continue
        fi

        if [ -L "$full_path" ]; then
            resolved="$(readlink -f "$full_path" 2>/dev/null || true)"
            if [[ -n "$resolved" && "$resolved" == "$DOTFILES_DIR/"* ]]; then
                continue
            fi
        fi

        rm -rf -- "$full_path"
        removed_count=$((removed_count + 1))
    done < <(collect_stow_targets)

    success "Removed $removed_count existing path(s)"
}

choose_stow_prep_mode() {
    echo
    info "Before stowing, choose how to handle existing config files:"
    echo "1) Backup existing targets automatically"
    echo "2) Remove existing targets"
    echo "3) I'll back them up manually first"
    echo
    read -r -p "Enter choice [1-3]: " prep_choice

    case "$prep_choice" in
        1)
            backup_existing_targets
            ;;
        2)
            remove_existing_targets
            ;;
        3)
            info "Manual backup selected. Back up your files now."
            read -r -p "Press Enter when you are ready to continue stowing..."
            ;;
        *)
            error "Invalid choice. Please run the script again and choose 1, 2, or 3."
            ;;
    esac
}

choose_stow_prep_mode

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

info "Updating tealdeer cache..."
tldr --update
success "Tealdeer cache updated"

info "Building bat theme cache..."
bat cache --build
success "bat cache built"

# ── Tmux plugins (TPM) ────────────────────────────────────────────────────────

info "Installing TPM and tmux plugins..."
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi
tmux new-session -d -s __bootstrap 2>/dev/null || true
tmux run-shell ~/.config/tmux/plugins/tpm/bin/install_plugins
tmux kill-session -t __bootstrap 2>/dev/null || true
success "Tmux plugins installed"

# ─────────────────────────────────────────────────────────────────────────────

success "Bootstrap complete! Restart your terminal or run: exec fish"
