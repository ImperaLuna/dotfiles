# ---------------------------------------------------------------------------- #
# 1. PATH and Environment Setup
# ---------------------------------------------------------------------------- #

# REMOVE /mnt PATHS
# PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/mnt/" | tr '\n' ':' | sed 's/:$//')

# CHECK FOR WINDOWS PATHS
# echo $PATH | tr ':' '\n' | grep mnt


# Initialize Homebrew environment variables
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Load any local environment
. "$HOME/.local/bin/env"


# ---------------------------------------------------------------------------- #
# 2. History Configuration
# ---------------------------------------------------------------------------- #

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

# History Options
setopt HIST_IGNORE_SPACE    # Don't save commands prefixed with a space
setopt HIST_IGNORE_DUPS     # Don't save duplicate commands
setopt SHARE_HISTORY        # Share history across all sessions


# ---------------------------------------------------------------------------- #
# 3. Zsh Options and Basic Aliases
# ---------------------------------------------------------------------------- #

# Change to a directory by just typing its name (auto-cd)
setopt autocd

# Navigation Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# Common Aliases
alias python=python3


# ---------------------------------------------------------------------------- #
# 4. Plugins and Frameworks
# ---------------------------------------------------------------------------- #

# Starship Prompt
eval "$(starship init zsh)"
#
# Zsh Autosuggestions
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
#
# Zsh Syntax Highlighting
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Zsh Autocomplete
source ~/.zsh/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# FZF (Fuzzy Finder) Key Bindings/Completions
eval "$(fzf --zsh)"

# ---------------------------------------------------------------------------- #
# 5. Completion Configuration
# ---------------------------------------------------------------------------- #

# UV Shell Completion
eval "$(uv generate-shell-completion zsh)"

