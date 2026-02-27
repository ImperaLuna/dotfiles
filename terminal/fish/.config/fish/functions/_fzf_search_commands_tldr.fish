function _fzf_search_commands_tldr --description "Search all commands with tldr preview. Replace the current token with the selected command."
    set -f token (commandline --current-token)

    set -f selected (complete -C "" 2>/dev/null \
        | _fzf_wrapper \
            --query "$token" \
            --exact \
            --delimiter '\t' \
            --nth '1' \
            --with-nth '1' \
            --preview 'tldr {1} 2>/dev/null | bat --paging=never --language=markdown' \
            --preview-window 'right:60%' \
            --prompt "Commands> " \
            --ansi)

    if test $status -eq 0 -a -n "$selected"
        # Extract just the command name (field before the tab)
        set -f cmd (string split \t "$selected")[1]
        commandline --current-token --replace -- $cmd
    end

    commandline --function repaint
end
