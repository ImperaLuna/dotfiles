# Dotfiles

My personal configuration files for Arch Linux.

## Prerequisites

- Fresh Arch Linux installation
- Non-root user with sudo privileges
- Internet connection

---

## Terminal Setup

Installs and configures: fish, starship, and core CLI tools.
```bash
mkdir ~/dotfiles
git clone https://github.com/ImperaLuna/dotfiles.git ~/dotfiles
cd ~/dotfiles/setup
chmod +x terminal_setup.sh
./terminal_setup.sh
```

**What gets stowed:** `fish`, `git`, `starship`, `yazi` `btop` 

---

## Hyprland Setup

---

## Applications Setup



---

## Manual Stow

To stow a specific config manually:
```bash
cd ~/dotfiles
stow fish
```
