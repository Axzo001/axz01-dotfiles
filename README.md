# axz01-dotfiles

My personal Linux terminal configuration — **Zsh + Oh My Zsh + Starship + Fastfetch + Atuin**.

**Supports:** Arch Linux · Fedora Workstation (and derivatives)  
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
1. **Auto-detect your distro** (Arch, Fedora, or derivatives) and select the package manager (`paru` / `yay` / `pacman` / `dnf`)
2. **Ask which terminal** you want: GNOME Console (default) or Ghostty
3. Ask if you want to remove the alternate terminal (optional)
4. Install all dependencies, JetBrainsMono Nerd Font, Oh My Zsh + plugins, and deploy configs

## Distro Support

| Feature | Arch Linux & Derivatives | Fedora Workstation & Derivatives |
|---|---|---|
| Package manager | `paru` / `yay` (AUR) / `pacman` | `dnf` |
| Font | `ttf-jetbrains-mono-nerd` | Automated Nerd Font installer |
| Starship | `paru -S starship` | `dnf install starship` (or official script) |
| Atuin | `paru -S atuin` | `dnf install atuin` (or official script) |
| Ghostty | `paru -S ghostty` | `dnf install ghostty` (Fedora 42+ or repo) |
| GNOME Console | `paru -S gnome-console` | `dnf install gnome-console` |

## Terminal Options

### GNOME Console (default)
* Font: JetBrainsMono Nerd Font 13
* Theme: Night (Dark Mode)
* Scrollback: 10,000 lines

### Ghostty Keybindings
* `Ctrl + Shift + T`: Open new tab
* `Ctrl + Shift + W`: Close tab/split pane
* `Ctrl + Tab` / `Ctrl + Shift + Tab`: Cycle tabs
* `Ctrl + 1–5`: Switch to tab 1–5
* `Ctrl + Shift + \`: Split pane vertically (right)
* `Ctrl + Shift + -`: Split pane horizontally (down)
* `Ctrl + Shift + H/J/K/L`: Navigate split panes
* `Ctrl + =` / `Ctrl + -`: Increase/decrease font size
* `Ctrl + 0`: Reset font size
* `Ctrl + Shift + C` / `Ctrl + Shift + V`: Copy / paste
* `F11`: Toggle fullscreen

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

| Alias | Arch (`paru`) | Fedora (`dnf`) |
|---|---|---|
| `pins` | `paru -S` | `sudo dnf install` |
| `pupd` | `paru -Syu` | `sudo dnf upgrade` |
| `psrc` | `paru -Ss` | `dnf search` |
| `prem` | `paru -Rns` | `sudo dnf remove` |
| `pclean` | clean pacman + paru cache | `sudo dnf clean all` |
| `porphan` | remove orphan packages safely | `sudo dnf autoremove` |
| `plist` | list explicitly installed packages | `dnf list installed` |
| `pinfo` | show package details | `dnf info` |
| `pfiles` | list files in package | `rpm -ql` |

## Custom Shell Functions & Aliases

* `fetch`: Run `fastfetch` to display system details
* `gac <message>`: `git add -A && git commit -m "<message>"`
* `mkcd <dir>`: Create a directory and `cd` into it
* `up <num>`: Go up N directories (e.g. `up 3`)
* `preview`: Browse files with `bat` + `fzf` live preview
* `fh`: Interactive history search with `fzf`
* `reload`: Reload the shell configuration
