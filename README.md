# axz01-dotfiles

Arch Linux Ghostty + Zsh + Starship terminal setup.

This repository contains my personal terminal configuration, designed to provide a clean, modern, and highly productive command-line experience matching the GNOME Adwaita Dark theme.

## Features

* **🐚 Shell**: Zsh + Oh My Zsh with a robust plugin stack.
* **🚀 Prompt**: [Starship](https://starship.rs/) configured with a clean, bug-free, and minimal layout showing OS icon, username, directory, git branch/status, and command duration.
* **🖥 Terminal**: [Ghostty](https://ghostty.org/) styled with the official `"Adwaita Dark"` theme, JetBrainsMono Nerd Font, custom keyboard shortcuts (tabs, splits, resizing), and titlebar buttons intact.
* **⚡ Fastfetch**: Custom compact fastfetch layout showing title, OS, host, kernel, uptime, shell, desktop environment, terminal, CPU, GPU, and RAM in default theme colors.
* **🔍 Fuzzy Finder**: Integrated `fzf` for tab completions (`fzf-tab`), history search, directory jumps, and file previews.

## Oh My Zsh Plugins Included

1. `git` & `github`
2. `node` & `npm`
3. `python` & `pip`
4. `rust` & `golang`
5. `docker` & `docker-compose`
6. `sudo` (double ESC to prepend sudo)
7. `extract` (universal archive extraction)
8. `colored-man-pages`
9. `zsh-completions` (additional completions)
10. `fzf-tab` (fuzzy tab completions)
11. `you-should-use` (alias reminder)
12. `zsh-autosuggestions` (fish-like autocomplete suggestions)
13. `zsh-history-substring-search` (type to search command history)
14. `zsh-syntax-highlighting` (real-time command syntax checks)

## Active Keybindings & Shortcuts

| Hotkey | Action |
| --- | --- |
| `Tab` | Open interactive `fzf-tab` fuzzy completion menu |
| `Right Arrow` / `Ctrl+F` | Accept inline command autocomplete suggestion |
| `Alt+Right Arrow` | Accept suggestion word-by-word |
| `↑ / ↓` or `Ctrl+P/N` | Search history for commands matching the typed prefix |
| `Ctrl+R` | Open Atuin fuzzy history list |
| `Ctrl+T` | Search for local files and paste path to command line |
| `Alt+C` | Search for local subdirectories and instantly `cd` into selection |
| `Ctrl+X Ctrl+E` | Open current command buffer in Zed for editing |
| `Esc Esc` | Prepend `sudo` to the current command |

### Ghostty Terminal Shortcuts
* `Ctrl + T`: Open new tab
* `Ctrl + Tab` / `Ctrl + Shift + Tab`: Cycle tabs
* `Ctrl + 1` to `Ctrl + 5`: Switch to specific tab
* `Ctrl + Shift + \`: Split pane vertically (right)
* `Ctrl + Shift + -`: Split pane horizontally (down)
* `Ctrl + Shift + H/J/K/L`: Navigate split panes
* `Ctrl + W`: Close active tab/split pane
* `Ctrl + =` / `Ctrl + -`: Increase/decrease font size

## Installation

To deploy this configuration on Arch Linux, clone the repository and run the installer:

```bash
git clone https://github.com/Axzo001/axz01-dotfiles.git
cd axz01-dotfiles
chmod +x install.sh
./install.sh
```

*(Note: The script will ask for your `sudo` password to install dependencies and optionally uninstall `gnome-console`.)*
