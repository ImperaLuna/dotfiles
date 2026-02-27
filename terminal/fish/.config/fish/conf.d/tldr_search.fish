if not status is-interactive
    exit
end

# Ctrl+/ — open fzf command search with tldr preview
# Prefills with whatever is currently typed (prefix match, not fuzzy)
# e.g. typing "grep" then Ctrl+/ shows all commands starting with "grep" + tldr on the right
for mode in default insert
    bind --mode $mode ctrl-/ _fzf_search_commands_tldr
    bind --mode $mode ctrl-_ _fzf_search_commands_tldr  # same byte (0x1f) as ctrl-/, needed inside tmux
end
