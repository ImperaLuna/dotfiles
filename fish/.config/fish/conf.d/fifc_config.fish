    # Show package info from repos, falls back to AUR via yay/paru
    fifc \
        -n 'string match -qr "^(pacman|paru|yay)" "$fifc_commandline"' \
        -p 'pacman -Si "$fifc_candidate" 2>/dev/null; or yay -Si "$fifc_candidate" 2>/dev/null; or paru -Si "$fifc_candidate" 2>/dev/null' \
        -O 1

    # Show commit history for branches, or changed files for commit hashes
    fifc \
        -n 'string match -qr "^git" "$fifc_commandline"' \
        -p 'git log --oneline --color=always "$fifc_candidate" 2>/dev/null; or git show --stat --color=always "$fifc_candidate" 2>/dev/null' \
        -O 1

    # Show service status, with tldr appended below for quick reference
    fifc \
        -n 'string match -qr "^systemctl" "$fifc_commandline"' \
        -p 'systemctl status "$fifc_candidate" 2>/dev/null; printf "\n---\n"; tldr "$fifc_candidate" 2>/dev/null' \
        -O 1

    # Preview directories with eza tree view
    fifc \
        -n 'test -d "$fifc_candidate"' \
        -p 'eza --tree --level=2 --color=always --icons "$fifc_candidate"' \
        -O 1
