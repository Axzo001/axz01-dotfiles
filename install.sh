#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Dotfiles Installer — Arch Linux Terminal Setup
#  A complete Zsh + Oh My Zsh + Starship + Ghostty + Fastfetch
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# Colors
CYAN='\033[38;2;0;180;216m'; TEAL='\033[38;2;0;229;160m'
MINT='\033[38;2;77;255;210m'; RED='\033[0;31m'
BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${TEAL}${BOLD}❯${RESET} $*"; }
ok()   { echo -e "${MINT}${BOLD}✓${RESET} $*"; }
warn() { echo -e "${CYAN}${BOLD}⚠${RESET} $*"; }
error() { echo -e "${RED}${BOLD}✗${RESET} $*"; exit 1; }

echo ""
echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
echo -e "${TEAL}${BOLD}│       Axz01 Dotfiles — Arch Linux Terminal Setup   │${RESET}"
echo -e "${TEAL}${BOLD}│       Zsh │ Ghostty │ Starship │ Fastfetch         │${RESET}"
echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Uninstall gnome-console ─────────────────────────────────────
if pacman -Qi gnome-console &>/dev/null; then
  log "Removing gnome-console (will ask for password)..."
  sudo pacman -Rns --noconfirm gnome-console || warn "Failed to remove gnome-console, skipping..."
  ok "gnome-console removed."
else
  log "gnome-console is not installed."
fi

# ── 2. Install Ghostty and System Dependencies ────────────────────
log "Installing ghostty and dependencies via yay..."
if ! command -v yay &>/dev/null; then
  error "yay is not installed. Please install yay (AUR helper) first."
fi

yay -S --noconfirm --needed \
  ghostty zsh starship fzf bat eza fd zoxide atuin \
  ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-mono

ok "System packages installed."

# ── 3. Install Oh My Zsh ──────────────────────────────────────────
# Using git clone directly to prevent issues with Ghostty shell-integration path
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing Oh My Zsh via git clone..."
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  ok "Oh My Zsh installed."
else
  warn "Oh My Zsh already installed, skipping clone."
fi

# ── 4. Clone Oh My Zsh Plugins ─────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_plugin() {
  local name="$1" url="$2" dest="$3"
  if [ ! -d "$dest" ]; then
    log "Cloning plugin: ${BOLD}$name${RESET}..."
    git clone --depth=1 "$url" "$dest"
    ok "$name cloned."
  else
    warn "$name already exists — pulling updates..."
    git -C "$dest" pull --ff-only --quiet 2>/dev/null || true
  fi
}

clone_plugin "zsh-completions"              "https://github.com/zsh-completions/zsh-completions"        "$ZSH_CUSTOM/plugins/zsh-completions"
clone_plugin "fzf-tab"                      "https://github.com/Aloxaf/fzf-tab"                         "$ZSH_CUSTOM/plugins/fzf-tab"
clone_plugin "you-should-use"               "https://github.com/MichaelAquilina/zsh-you-should-use"     "$ZSH_CUSTOM/plugins/you-should-use"
clone_plugin "zsh-autosuggestions"          "https://github.com/zsh-users/zsh-autosuggestions"          "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
clone_plugin "zsh-syntax-highlighting"      "https://github.com/zsh-users/zsh-syntax-highlighting"      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ── 5. Copy Configuration Templates ────────────────────────────────
log "Deploying configurations..."

# Create target directories
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/fastfetch"

# Backup existing configs if they exist
backup_file() {
  local file="$1"
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    warn "Backing up existing config: $file to ${file}.bak"
    cp "$file" "${file}.bak"
  fi
}

backup_file "$HOME/.zshrc"
backup_file "$HOME/.config/starship.toml"
backup_file "$HOME/.config/fastfetch/config.jsonc"
backup_file "$HOME/.config/ghostty/config.ghostty"

# Copy configs
cp "$SCRIPT_DIR/config/zshrc"            "$HOME/.zshrc"
cp "$SCRIPT_DIR/config/starship.toml"    "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/config/fastfetch.jsonc"  "$HOME/.config/fastfetch/config.jsonc"
cp "$SCRIPT_DIR/config/ghostty.config"   "$HOME/.config/ghostty/config.ghostty"

ok "Configurations deployed."

# ── 6. Change default shell to Zsh ─────────────────────────────────
ZSH_PATH="$(which zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  log "Setting default shell to zsh..."
  chsh -s "$ZSH_PATH"
  ok "Default shell changed to zsh (takes effect on next login)."
else
  log "zsh is already default shell."
fi

# ── 7. Initialize atuin history import ──────────────────────────────
if command -v atuin &>/dev/null; then
  log "Importing history into atuin..."
  atuin import auto 2>/dev/null || true
  ok "Atuin history setup complete."
fi

echo ""
echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
echo -e "${TEAL}${BOLD}│   ✓  Installation Complete!                        │${RESET}"
echo -e "${TEAL}│   Please restart Ghostty or run: exec zsh          │${RESET}"
echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
echo ""
