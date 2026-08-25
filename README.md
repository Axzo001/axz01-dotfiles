# axz01-dotfiles

My personal terminal setup for Arch Linux and Fedora Workstation.

Built around **Zsh**, **Oh My Zsh**, **Starship**, **Fastfetch**, and **Atuin**, with configs tailored for **GNOME Console** and **Ghostty**.

![Showcase](assets/showcase.png)

## Installation

```bash
git clone https://github.com/Axzo001/axz01-dotfiles.git
cd axz01-dotfiles
chmod +x install.sh
./install.sh
```

The installer handles:
* Detecting your distro (`paru`, `yay`, `pacman`, or `dnf`)
* Setting up your chosen terminal (GNOME Console or Ghostty)
* Installing JetBrainsMono Nerd Font and system dependencies
* Setting up Oh My Zsh, custom plugins, and deploying all configs

## What's Inside

* **Shell**: Zsh + Oh My Zsh (autosuggestions, syntax highlighting, fzf-tab, substring search)
* **Prompt**: Starship (minimal teal/mint layout with git status, duration, and distro icon)
* **History**: Atuin (searchable shell history with rich metadata)
* **Terminal**: GNOME Console & Ghostty (dark teal glassmorphic theme)
* **CLI Tools**: `eza` (modern ls), `bat` (syntax-highlighted cat), `zoxide` (smart directory jumping), `ripgrep`, and `fd`

## Quick Aliases & Helpers

* `pins`, `pupd`, `prem`, `psrc`, `pclean`, `porphan` — Unified package manager commands across Arch and Fedora
* `gac "<msg>"` — Quick `git add -A && git commit -m "<msg>"`
* `mkcd <dir>` — Make directory and `cd` straight into it
* `up <n>` — Jump up `n` parent directories (`up 3`)
* `preview` — Interactive fuzzy file browser with live syntax preview
* `z <dir>` — Jump to frequent folders instantly using Zoxide
