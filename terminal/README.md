# Terminal Setup

Tools installed and configured by `setup/terminal_setup.sh`.

---

## Shell

### [fish](https://fishshell.com/)
Modern shell with autosuggestions, syntax highlighting, and tab completions out of the box.

| Command | Description |
|---------|-------------|
| `ctrl+r` | Search shell history with fzf |
| `ctrl+alt+f` | Search files in current dir with fzf |
| `ctrl+alt+l` | Search git log with fzf |
| `ctrl+alt+s` | Search git status with fzf |
| `ctrl+/` | Search all commands with tldr preview |
| `tab` | fifc-powered fuzzy tab completion |

### [fisher](https://github.com/jorgebucaran/fisher)
Fish plugin manager.

| Command | Description |
|---------|-------------|
| `fisher install <user/repo>` | Install a plugin |
| `fisher update` | Update all plugins |
| `fisher remove <user/repo>` | Remove a plugin |

**Plugins installed:**
- **fzf.fish** — fzf keybindings for fish (ctrl+r, ctrl+alt+l, etc.)
- **fifc** — fzf-powered tab completions with previews
- **fish-abbreviation-tips** — reminds you of abbreviations when you type the full command
- **sponge** — removes failed commands from history

### [starship](https://starship.rs/)
Cross-shell prompt. Configured in `starship/`.

### [zoxide](https://github.com/ajeetdsouza/zoxide)
Smarter `cd` — learns your most visited directories.

| Command | Description |
|---------|-------------|
| `cd <dir>` | Jump to directory (replaces cd) |
| `cd <partial>` | Jump to best match for partial name |
| `cdi` | Interactive fuzzy jump |

---

## File Tools

### [bat](https://github.com/sharkdp/bat)
Drop-in replacement for `cat` with syntax highlighting, line numbers, and git integration.

| Command | Description |
|---------|-------------|
| `bat file.txt` | View file with syntax highlighting |
| `bat --plain file.txt` | No decorations — useful for copying output |
| `bat --language=json -` | Read from stdin with explicit language |
| `bat -A file.txt` | Show non-printable characters |
| `command \| bat` | Pipe any output through bat |

### [eza](https://github.com/eza-community/eza)
Modern replacement for `ls` with icons, git status, and tree view. Aliased to `ls`.

| Command | Description |
|---------|-------------|
| `ls` | List with icons (aliased) |
| `ls -la` | Long format with hidden files |
| `eza --tree` | Tree view |
| `eza --tree --level=2` | Tree view limited to 2 levels |
| `eza --git` | Show git status per file |

### [ripgrep](https://github.com/BurntSushi/ripgrep) (`rg`)
Extremely fast grep replacement. Respects `.gitignore` by default.

| Command | Description |
|---------|-------------|
| `rg "pattern"` | Search in current directory recursively |
| `rg "pattern" file.txt` | Search in a specific file |
| `rg -i "pattern"` | Case-insensitive search |
| `rg -t py "pattern"` | Search only Python files |
| `rg -l "pattern"` | List only matching file names |
| `rg --hidden "pattern"` | Include hidden files |

### [fd](https://github.com/sharkdp/fd)
Simple and fast replacement for `find`.

| Command | Description |
|---------|-------------|
| `fd "pattern"` | Find files matching pattern |
| `fd -e txt` | Find by extension |
| `fd -H "pattern"` | Include hidden files |
| `fd -t d "pattern"` | Find directories only |
| `fd "pattern" /path` | Search in specific directory |
| `fd -x cmd` | Execute command on each result |

---

## Git

### [git-delta](https://github.com/dandavison/delta)
Syntax-highlighted diff viewer. Used automatically by git and fzf git log preview.

| Command | Description |
|---------|-------------|
| `git diff` | Delta is set as default pager |
| `git log` | Enhanced log view |
| `n / N` | Jump to next/previous diff section |

### [lazygit](https://github.com/jesseduffield/lazygit)
Terminal UI for git.

| Key | Description |
|-----|-------------|
| `lazygit` | Open in current repo |
| `space` | Stage/unstage file |
| `c` | Commit |
| `p` | Pull |
| `P` | Push |
| `b` | Branch menu |

---

## Neovim

### [neovim](https://neovim.io/)
Configured with LazyVim. See `nvim/` for config.

| Command | Description |
|---------|-------------|
| `nvim file` | Open file |
| `:Lazy` | Plugin manager UI |
| `:Mason` | LSP/linter installer |
| `:checkhealth` | Diagnose issues |

### [tree-sitter-cli](https://github.com/tree-sitter/tree-sitter)
Required by nvim-treesitter for building parsers.

---

## File Manager

### [yazi](https://github.com/sxyazi/yazi)
Blazing fast terminal file manager with previews for images, PDFs, archives, and more.

| Key | Description |
|-----|-------------|
| `yazi` | Open in current directory |
| `hjkl` | Navigate |
| `enter` | Open file/directory |
| `space` | Select file |
| `y` | Yank (copy) |
| `d` | Cut |
| `p` | Paste |
| `a` | Create file/directory |
| `r` | Rename |
| `tab` | Toggle preview |
| `.` | Toggle hidden files |

---

## System Tools

### [btop](https://github.com/aristocratos/btop)
Resource monitor — CPU, memory, processes, network, disk.

| Key | Description |
|-----|-------------|
| `btop` | Open monitor |
| `f` | Filter processes |
| `k` | Kill process |
| `m` | Change memory display |

### [dust](https://github.com/bootandy/dust)
Intuitive `du` replacement — shows disk usage as a tree.

| Command | Description |
|---------|-------------|
| `dust` | Disk usage of current directory |
| `dust -d 2` | Limit depth to 2 levels |
| `dust /path` | Disk usage of specific path |

### [duf](https://github.com/muesli/duf)
Better `df` — shows disk usage per mount point.

| Command | Description |
|---------|-------------|
| `duf` | Show all mount points |
| `duf /path` | Show specific mount point |

### [tealdeer](https://github.com/tealdeer-rs/tealdeer) (`tldr`)
Fast tldr client — simplified man pages with practical examples. Aliased as `man`.

| Command | Description |
|---------|-------------|
| `tldr <command>` | Show examples for a command |
| `tldr --update` | Update the local cache |

> **Tip:** In the `ctrl+/` command search menu, hold **Shift** and drag to select text from the preview — lets you copy individual lines from the tldr page.

---

## Terminal Multiplexer

### [tmux](https://github.com/tmux/tmux)
Terminal multiplexer — multiple windows and panes in one terminal. See `tmux/` for config.

| Command | Description |
|---------|-------------|
| `tmux` | Start new session |
| `tmux new -s name` | Start named session |
| `tmux attach` | Attach to last session |
| `tmux ls` | List sessions |

---

## Fonts & Clipboard

### ttf-jetbrains-mono-nerd
JetBrains Mono patched with Nerd Fonts icons — used by yazi, eza, and the prompt.

### wl-clipboard
Wayland clipboard utilities (`wl-copy`, `wl-paste`). Used by neovim and other tools.

| Command | Description |
|---------|-------------|
| `wl-copy < file` | Copy file contents to clipboard |
| `wl-paste` | Paste from clipboard |
| `command \| wl-copy` | Pipe output to clipboard |
