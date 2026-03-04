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

info "Checking for yay..."
if ! command -v yay &>/dev/null; then
    error "yay not found — run terminal_setup.sh first."
fi

# ── Hyprland ──────────────────────────────────────────────────────────────────

info "Installing Hyprland and Wayland stack..."
yay -S --needed --noconfirm \
    hyprland \
    hypridle \
    hyprlock \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk

info "Installing session/auth utilities..."
yay -S --needed --noconfirm \
    polkit-kde-agent

# Optional extras
# yay -S --needed --noconfirm hyprpaper hyprpicker

# ── Audio ─────────────────────────────────────────────────────────────────────

info "Installing audio stack..."
yay -S --needed --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    wireplumber

# ── Quickshell ────────────────────────────────────────────────────────────────

info "Installing Quickshell..."
yay -S --needed --noconfirm quickshell-git

# ── Apps ──────────────────────────────────────────────────────────────────────

info "Installing apps used by current Hypr config..."
yay -S --needed --noconfirm \
    kitty \
    nautilus \    zen-browser-bin \
    python

# ── Desktop utilities ─────────────────────────────────────────────────────────

info "Installing desktop utilities used by keybinds/launcher..."
yay -S --needed --noconfirm \
    brightnessctl \
    playerctl \
    wl-clipboard

# Optional extras
# yay -S --needed --noconfirm grim slurp cliphist

# ── Theming ───────────────────────────────────────────────────────────────────

# info "Installing themes and fonts..."
# yay -S --needed --noconfirm \
#     noto-fonts \
#     noto-fonts-emoji \
#     papirus-icon-theme \
#     catppuccin-gtk-theme-mocha \
#     qt6ct \
#     kvantum

# ── Dark theme: GTK ───────────────────────────────────────────────────────────

# info "Configuring GTK dark theme..."
#
# mkdir -p "$HOME/.config/gtk-3.0"
# cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
# [Settings]
# gtk-application-prefer-dark-theme=true
# gtk-theme-name=catppuccin-mocha-standard-blue-dark
# gtk-icon-theme-name=Papirus-Dark
# gtk-cursor-theme-name=Adwaita
# gtk-cursor-theme-size=24
# gtk-font-name=Noto Sans 11
# EOF
#
# mkdir -p "$HOME/.config/gtk-4.0"
# cat > "$HOME/.config/gtk-4.0/settings.ini" <<'EOF'
# [Settings]
# gtk-application-prefer-dark-theme=true
# gtk-theme-name=catppuccin-mocha-standard-blue-dark
# gtk-icon-theme-name=Papirus-Dark
# gtk-cursor-theme-name=Adwaita
# gtk-cursor-theme-size=24
# gtk-font-name=Noto Sans 11
# EOF

# ── Dotfiles ──────────────────────────────────────────────────────────────────

STOW_PACKAGES=(hyprland quickshell)

collect_stow_targets() {
    local package
    local raw_output
    local desktop_dir="$DOTFILES_DIR/desktop"

    (
        cd "$desktop_dir" || exit 1
        for package in "${STOW_PACKAGES[@]}"; do
            raw_output=$(stow -n -v -R --target ~ "$package" 2>/dev/null || true)
            awk '/^LINK: / {print $2}' <<< "$raw_output"
        done
    ) | sort -u
}

backup_existing_targets() {
    local backup_dir="$HOME/.config/desktop-dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
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

info "Stowing desktop dotfiles..."
cd "$DOTFILES_DIR/desktop"
for package in "${STOW_PACKAGES[@]}"; do
    info "Stowing $package..."
    stow --target ~ --restow "$package"
done

success "Desktop setup complete! Log out and select Hyprland from your display manager."
