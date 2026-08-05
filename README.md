# axz01-dotfiles

My personal Linux terminal configuration — **Zsh + Oh My Zsh + Starship + Fastfetch + Atuin**.

**Supports:** Arch Linux · Fedora Workstation  
**Terminal options:** GNOME Console · Ghostty

![Showcase](assets/showcase.png)

## Installation

```bash
git clone https://github.com/Axzo001/axz01-dotfiles.git
cd axz01-dotfiles
chmod +x install.sh
./install.sh
```

The installer will:
1. **Auto-detect your distro** (Arch or Fedora) and use the right package manager (`paru` / `dnf`)
2. **Ask which terminal** you want: GNOME Console (default) or Ghostty
3. Remove the other terminal if already installed (you can skip)
4. Install all dependencies, Oh My Zsh + plugins, and deploy configs

## Distro Support

| Feature | Arch Linux | Fedora Workstation |
|---|---|---|
| Package manager | `paru` (AUR) | `dnf` |
| Starship | `paru -S starship` | Official install script |
| Atuin | `paru -S atuin` | Official install script |
| Ghostty | `paru -S ghostty` | `dnf install ghostty` (Fedora 42+) |
| GNOME Console | `paru -S gnome-console` | `dnf install gnome-console` |

## Terminal Options

### GNOME Console (default)
* Font: JetBrainsMono Nerd Font 13
* Theme: Night (Dark Mode)
* Scrollback: 10,000 lines

### Ghostty Keybindings
* `Ctrl + T`: Open new tab
* `Ctrl + W`: Close tab/split pane
* `Ctrl + Tab` / `Ctrl + Shift + Tab`: Cycle tabs
* `Ctrl + 1–5`: Switch to tab
* `Ctrl + Shift + \`: Split pane vertically (right)
* `Ctrl + Shift + -`: Split pane horizontally (down)
* `Ctrl + Shift + H/J/K/L`: Navigate split panes

## Zsh / Command Line Shortcuts

* `↑` / `↓` (or `Ctrl + P` / `Ctrl + N`): Search history (via `zsh-history-substring-search`)
* `Right Arrow` (or `Ctrl + F`): Accept autocomplete suggestion
* `Alt + Right Arrow`: Accept suggestion word-by-word
* `Ctrl + X Ctrl + E`: Open current command in `$EDITOR`
* `Esc Esc`: Prepend `sudo` to the current command
* `Tab`: Open fuzzy completion list (via `fzf-tab`)
* `Ctrl + R`: Open Atuin history search
* `Ctrl + T`: Search files with `fzf`
* `Alt + C`: `cd` into a folder with `fzf`

## Package Manager Aliases (distro-aware)

| Alias | Arch (paru) | Fedora (dnf) |
|---|---|---|
| `pins` | `paru -S` | `dnf install` |
| `pupd` | `paru -Syu` | `dnf upgrade` |
| `psrc` | `paru -Ss` | `dnf search` |
| `prem` | `paru -Rns` | `dnf remove` |
| `pclean` | clean pacman+paru | `dnf clean all` |
| `porphan` | remove orphans | `dnf autoremove` |

## Custom Shell Functions & Aliases

* `fetch`: Run `fastfetch` to display system details
* `gac <message>`: `git add -A && git commit -m "<message>"`
* `mkcd <dir>`: Create a directory and `cd` into it
* `up <num>`: Go up N directories (e.g. `up 3`)
* `preview`: Browse files with `bat` + `fzf` live preview
* `reload`: Reload the shell configuration
