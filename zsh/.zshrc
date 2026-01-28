#!/bin/zsh

# ============================================================================
# ZINIT PLUGIN MANAGER
# ============================================================================

# Set zinit directory (follows XDG spec)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Install zinit if missing
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Load plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

autoload -U compinit && compinit

# ============================================================================
# HISTORY
# ============================================================================

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE
HISTDUP=erase

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ============================================================================
# KEY BINDINGS
# ============================================================================

bindkey '^Z' undo
bindkey "^[[3~" delete-char

# ============================================================================
# COMPLETION
# ============================================================================

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Use ls colors for completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Use fzf for completion menu
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# ============================================================================
# ALIASES & FUNCTIONS
# ============================================================================

alias ls='eza --icons --color=always'
alias vim='nvim'
# PyCharm helper: pycharm --venv prints venv path, otherwise launches PyCharm
pycharm() {
    if [ "$1" = "--venv" ]; then
        if [ -d ".venv" ]; then
            echo "$(pwd)/.venv/bin/python3"
        fi
    else
        PLACEHOLDER_PATH_TO_PYCHARM "$@"
    fi
}

# ============================================================================
# TOOL INITIALIZATION
# ============================================================================

eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"
