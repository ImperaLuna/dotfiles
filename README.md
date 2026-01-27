# Terminal Configuration Setup

A modern, customized terminal environment using WezTerm, zsh, Starship prompt, and various CLI enhancements.

## Core Components

This setup includes:
- **WezTerm**: Modern GPU-accelerated terminal emulator
- **zsh**: Advanced shell with better scripting and completion
- **zinit**: Fast and flexible zsh plugin manager
- **Starship**: Cross-shell prompt with customization
- **Modern CLI tools**: eza, fzf, bat, and others

## Installation Steps

### 1. Install Core Dependencies

Install the base requirements using your distribution's package manager:

**Debian/Ubuntu based:**
```bash
sudo apt update
sudo apt install -y git curl zsh stow
```

**Arch based:**
```bash
sudo pacman -S git curl zsh stow
```

**Fedora/RHEL based:**
```bash
sudo dnf install -y git curl zsh stow
```

### 2. Install WezTerm

**Option A: Using package manager (if available)**

Check [WezTerm installation docs](https://wezfurlong.org/wezterm/install/linux.html) for your distro.

### 3. Install Starship Prompt

```bash
curl -sS https://starship.rs/install.sh | sh
```

### 4. Install Modern CLI Tools

**eza (modern ls replacement):**
```bash
# Check https://github.com/eza-community/eza for latest installation method
# Debian/Ubuntu:
sudo apt install -y eza

# Or use cargo:
cargo install eza
```

**fzf (fuzzy finder):**
```bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
```

**bat (better cat):**
```bash
# Debian/Ubuntu:
sudo apt install -y bat
# Note: On Debian/Ubuntu, the binary might be named 'batcat'

# Arch:
sudo pacman -S bat

# Or use cargo:
cargo install bat
```

**Other useful tools:**
```bash
# Install based on your package manager
# fd (better find), ripgrep (better grep), zoxide (smarter cd)
```

### 5. Set zsh as Default Shell

```bash
chsh -s $(which zsh)
```

Log out and log back in for the change to take effect.


### 7. Clone Your Dotfiles Repository

```bash
cd ~
git clone <your-dotfiles-repo-url> dotfiles
cd dotfiles
```

### 8. Deploy Configuration with GNU Stow

```bash
# From your dotfiles directory
cd ~/dotfiles

# Stow everything at once
stow */
```


### 9. Reload Your Shell

```bash
# Open a new terminal or reload zsh
source ~/.zshrc
```


