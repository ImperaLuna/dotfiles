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

**What gets stowed:** `fish`, `git`, `starship`, `yazi`, `btop`, `nvim`, `lazygit`

---

## Hyprland Setup

---

## Applications Setup



---

## Manual Stow

Configs are split into category directories (`terminal/`, `apps/`, `desktop/`). Stow must be run from inside the category directory with `--target ~` since the stow directory is no longer directly inside `~`.

Stow a single package:
```bash
cd ~/dotfiles/terminal
stow --target ~ fish
```

Stow all packages in a category:
```bash
cd ~/dotfiles/terminal
stow --target ~ */
```

Restow all (e.g. after moving files or fixing broken links):
```bash
cd ~/dotfiles/terminal
stow --target ~ --restow */
```
