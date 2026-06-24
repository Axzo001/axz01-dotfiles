# axz01-dotfiles

My personal Arch Linux terminal configuration (Zsh + Ghostty + Starship + Fastfetch).

## Installation

```bash
git clone https://github.com/Axzo001/axz01-dotfiles.git
cd axz01-dotfiles
chmod +x install.sh
./install.sh
```

## Custom Keybindings and Shortcuts

These are the keyboard shortcuts changed from the default system and shell configurations:

### Ghostty Terminal Shortcuts
* `Ctrl + T`: Open new tab (replaces default `Super + T`)
* `Ctrl + W`: Close active tab/split pane (replaces default `Super + W`)
* `Ctrl + Tab` / `Ctrl + Shift + Tab`: Cycle next/previous tab
* `Ctrl + 1` to `Ctrl + 5`: Switch to specific tab
* `Ctrl + Shift + \`: Split pane vertically (right)
* `Ctrl + Shift + -`: Split pane horizontally (down)
* `Ctrl + Shift + H/J/K/L`: Navigate split panes (left, down, up, right)

### Zsh / Command Line Shortcuts
* `↑` / `↓` (or `Ctrl + P` / `Ctrl + N`): Search history for commands starting with what you've typed (via `zsh-history-substring-search`)
* `Right Arrow` (or `Ctrl + F`): Accept autocomplete suggestion
* `Alt + Right Arrow`: Accept suggestion word-by-word
* `Ctrl + X Ctrl + E`: Open current command line in Zed editor to write/edit
* `Esc Esc`: Prepend `sudo` to the current command (via `sudo` plugin)
* `Tab`: Open fuzzy completion list (via `fzf-tab`)
* `Ctrl + R`: Open Atuin history list
* `Ctrl + T`: Search files with `fzf` and insert path
* `Alt + C`: Search folders with `fzf` and `cd` directly into it

### Custom Shell Functions & Aliases
* `gac <message>`: Run `git add -A && git commit -m "<message>"`
* `mkcd <dir>`: Create a directory and immediately `cd` into it
* `up <num>`: Go up multiple directories (e.g. `up 3`)
* `preview`: Open a fuzzy finder file list with a live file preview panel (`bat` + `fzf`)
* `reload`: Reload the shell configuration
