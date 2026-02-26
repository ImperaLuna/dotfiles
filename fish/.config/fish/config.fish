if status is-interactive
# Commands to run in interactive sessions can go here
end

starship init fish | source
zoxide init --cmd cd fish | source
set fish_greeting
