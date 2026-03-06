if status is-interactive
# Commands to run in interactive sessions can go here
end

function fish_user_key_bindings
    for mode in default insert
        bind --mode $mode \t _fifc
    end
end

starship init fish | source
zoxide init --cmd cd fish | source
set fish_greeting
