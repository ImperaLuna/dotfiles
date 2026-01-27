#!/bin/zsh
# Directory to store zinit & plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download zinit if missing
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

autoload -U compinit && compinit

# Key Bindings

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=$HISTSIZE
HISTDUP=erase

# History Options
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

bindkey '^Z' undo

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Keep using ls colors for completion matching
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# But alias ls itself to eza
alias ls='eza --icons --color=always'
pycharm() {
    if [ "$1" = "--venv" ]; then
        if [ -d ".venv" ]; then
            echo "$(pwd)/.venv/bin/python3"
        fi
    else
        PLACEHOLDER_PATH_TO_PYCHARM "$@"
    fi
}
eval "$(fzf --zsh)"
eval "$(zoxide init --cmd cd zsh)"
eval "$(starship init zsh)"

. "$HOME/.local/bin/env"
