#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Dotfiles Installer — Universal Linux Terminal Setup
#  Zsh + Oh My Zsh + Starship + Fastfetch + Atuin
#  Supports: Arch Linux (paru/yay/pacman), Fedora Workstation (dnf)
#  Terminal options: GNOME Console or Ghostty
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────
CYAN='\033[38;2;0;180;216m'; TEAL='\033[38;2;0;229;160m'
MINT='\033[38;2;77;255;210m'; RED='\033[0;31m'
BOLD='\033[1m'; RESET='\033[0m'

log()   { echo -e "${TEAL}${BOLD}❯${RESET} $*"; }
ok()    { echo -e "${MINT}${BOLD}✓${RESET} $*"; }
warn()  { echo -e "${CYAN}${BOLD}⚠${RESET} $*"; }
error() { echo -e "${RED}${BOLD}✗${RESET} $*"; exit 1; }
ask()   { echo -e "${TEAL}${BOLD}?${RESET} $*"; }

echo ""
echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
echo -e "${TEAL}${BOLD}│       Axz01 Dotfiles — Universal Terminal Setup    │${RESET}"
echo -e "${TEAL}${BOLD}│       Zsh │ Starship │ Fastfetch │ Atuin           │${RESET}"
echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 0. Detect Distribution ─────────────────────────────────────────
detect_distro() {
  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
  else
    DISTRO_ID="unknown"
    DISTRO_LIKE=""
  fi

  if [[ "$DISTRO_ID" == "arch" ]] || [[ "$DISTRO_LIKE" == *"arch"* ]] || [[ "$DISTRO_ID" =~ (endeavouros|manjaro|cachyos|garuda) ]]; then
    DISTRO="arch"
  elif [[ "$DISTRO_ID" == "fedora" ]] || [[ "$DISTRO_LIKE" == *"fedora"* ]] || [[ "$DISTRO_ID" =~ (nobara|bazzite|rhel|centos) ]]; then
    DISTRO="fedora"
  else
    warn "Unrecognized distro '$DISTRO_ID'. Attempting best-effort install."
    DISTRO="unknown"
  fi
  log "Detected distribution: ${BOLD}${DISTRO_ID}${RESET} (profile: ${DISTRO})"
}
detect_distro

# ── 1. Terminal Choice ─────────────────────────────────────────────
echo ""
ask "Which terminal do you want to configure?"
echo "  1) GNOME Console  (default, recommended)"
echo "  2) Ghostty        (GPU-accelerated, feature-rich)"
read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1/2] (default: 1): " TERM_CHOICE
TERM_CHOICE="${TERM_CHOICE:-1}"

case "$TERM_CHOICE" in
  2) TERMINAL="ghostty" ;;
  *) TERMINAL="gnome-console" ;;
esac
log "Selected terminal: ${BOLD}${TERMINAL}${RESET}"
echo ""

# ── 2. Remove Conflicting Terminal (Optional) ──────────────────────
remove_package() {
  local pkg="$1"
  case "$DISTRO" in
    arch)
      if pacman -Qi "$pkg" &>/dev/null; then
        paru -Rns --noconfirm "$pkg" 2>/dev/null || \
          yay -Rns --noconfirm "$pkg" 2>/dev/null || \
          sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null || \
          warn "Could not remove $pkg, skipping."
      fi
      ;;
    fedora)
      if rpm -q "$pkg" &>/dev/null; then
        sudo dnf remove -y "$pkg" 2>/dev/null || \
          warn "Could not remove $pkg, skipping."
      fi
      ;;
  esac
  return 0
}

ask "Do you want to remove the alternate terminal to avoid duplicates? [y/N]"
read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [y/N] (default: N): " PURGE_ALT
PURGE_ALT="${PURGE_ALT:-N}"

if [[ "$PURGE_ALT" =~ ^[Yy]$ ]]; then
  if [[ "$TERMINAL" == "gnome-console" ]]; then
    log "Removing Ghostty (if installed)..."
    remove_package "ghostty"
    if [[ "$DISTRO" == "arch" ]]; then
      remove_package "ghostty-shell-integration"
      remove_package "ghostty-terminfo"
    fi
    rm -rf "$HOME/.config/ghostty" "$HOME/.local/share/ghostty" "$HOME/.cache/ghostty"
    ok "Ghostty removed and purged."
  elif [[ "$TERMINAL" == "ghostty" ]]; then
    log "Removing GNOME Console (if installed)..."
    remove_package "gnome-console"
    ok "GNOME Console removed."
  fi
else
  log "Skipping removal of alternate terminal."
fi

# ── 3. Install System Dependencies ────────────────────────────────
log "Installing dependencies..."

install_arch() {
  # Detect AUR helper
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
  else
    warn "No AUR helper (paru/yay) found. Using pacman for official packages."
    AUR_HELPER="sudo pacman"
  fi
  log "Using package installer: ${BOLD}${AUR_HELPER}${RESET}"

  # Common packages
  $AUR_HELPER -S --noconfirm --needed \
    zsh starship fzf bat eza fd zoxide atuin ripgrep \
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols \
    fastfetch || warn "Some Arch packages failed to install, proceeding..."

  # Terminal-specific
  if [[ "$TERMINAL" == "ghostty" ]]; then
    $AUR_HELPER -S --noconfirm --needed ghostty || warn "Could not install Ghostty via AUR helper."
  else
    $AUR_HELPER -S --noconfirm --needed gnome-console || true
  fi
}

install_fedora() {
  # Enable RPM Fusion (free) if not already enabled
  if ! rpm -q rpmfusion-free-release &>/dev/null; then
    log "Enabling RPM Fusion Free repository..."
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      2>/dev/null || warn "Could not enable RPM Fusion, some packages may be unavailable."
  fi

  # Common packages available in Fedora repos
  sudo dnf install -y \
    zsh fzf bat eza fd-find zoxide ripgrep fastfetch curl \
    jetbrains-mono-fonts 2>/dev/null || warn "Some dnf packages failed to install."

  # Ensure Nerd Font is available on Fedora (standard repo font lacks glyphs)
  if ! fc-list : family 2>/dev/null | grep -iq "JetBrainsMono Nerd Font"; then
    log "Downloading JetBrainsMono Nerd Font for Fedora..."
    FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
    mkdir -p "$FONT_DIR"
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o /tmp/JetBrainsMono.tar.xz; then
      tar -xf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"
      rm -f /tmp/JetBrainsMono.tar.xz
      fc-cache -f "$FONT_DIR" 2>/dev/null || true
      ok "JetBrainsMono Nerd Font installed to ~/.local/share/fonts."
    else
      warn "Could not download JetBrainsMono Nerd Font automatically. You can install it manually from nerdfonts.com."
    fi
  fi

  # Fedora uses 'fdfind' instead of 'fd' — create a symlink in ~/.local/bin
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    ok "Created fd -> fdfind symlink in ~/.local/bin"
  fi

  # Starship: install via dnf or official installer script
  if ! command -v starship &>/dev/null; then
    log "Installing Starship..."
    sudo dnf install -y starship 2>/dev/null || \
      (curl -sS https://starship.rs/install.sh | sh -s -- --yes) || \
      warn "Starship installation failed."
  fi

  # Atuin: install via dnf or official installer script
  if ! command -v atuin &>/dev/null; then
    log "Installing Atuin..."
    sudo dnf install -y atuin 2>/dev/null || \
      (bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)) || \
      warn "Atuin install failed, skipping."
  fi

  # Terminal-specific
  if [[ "$TERMINAL" == "ghostty" ]]; then
    if sudo dnf install -y ghostty 2>/dev/null; then
      ok "Ghostty installed via dnf."
    else
      warn "Ghostty not found in standard repos. Install manually: https://ghostty.org"
    fi
  else
    sudo dnf install -y gnome-console 2>/dev/null || true
  fi
}

case "$DISTRO" in
  arch)    install_arch ;;
  fedora)  install_fedora ;;
  *)       warn "Unknown distro — skipping automated package install. Install manually: zsh fzf bat eza fd zoxide atuin starship fastfetch" ;;
esac

ok "System packages processed."

# ── 4. Install Oh My Zsh ──────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "Installing Oh My Zsh..."
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  ok "Oh My Zsh installed."
else
  warn "Oh My Zsh already installed — skipping."
fi

# ── 5. Clone Oh My Zsh Plugins ─────────────────────────────────────
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

clone_plugin "zsh-completions"              "https://github.com/zsh-users/zsh-completions"              "$ZSH_CUSTOM/plugins/zsh-completions"
clone_plugin "fzf-tab"                      "https://github.com/Aloxaf/fzf-tab"                         "$ZSH_CUSTOM/plugins/fzf-tab"
clone_plugin "you-should-use"               "https://github.com/MichaelAquilina/zsh-you-should-use"     "$ZSH_CUSTOM/plugins/you-should-use"
clone_plugin "zsh-autosuggestions"          "https://github.com/zsh-users/zsh-autosuggestions"          "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
clone_plugin "zsh-syntax-highlighting"      "https://github.com/zsh-users/zsh-syntax-highlighting"      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

# ── 6. Deploy Configuration Files ─────────────────────────────────
log "Deploying configurations..."

mkdir -p "$HOME/.config/fastfetch"

backup_file() {
  local file="$1"
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    warn "Backing up: $file → ${file}.bak"
    cp "$file" "${file}.bak"
  fi
}

backup_file "$HOME/.zshrc"
backup_file "$HOME/.config/starship.toml"
backup_file "$HOME/.config/fastfetch/config.jsonc"

cp "$SCRIPT_DIR/config/zshrc"          "$HOME/.zshrc"
cp "$SCRIPT_DIR/config/starship.toml"   "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/config/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# ── 7. Configure Terminal ──────────────────────────────────────────
if [[ "$TERMINAL" == "gnome-console" ]]; then
  if command -v gsettings &>/dev/null; then
    log "Configuring GNOME Console..."
    gsettings set org.gnome.Console use-system-font false 2>/dev/null || true
    gsettings set org.gnome.Console custom-font 'JetBrainsMono Nerd Font 13' 2>/dev/null || true
    gsettings set org.gnome.Console theme 'night' 2>/dev/null || true
    gsettings set org.gnome.Console scrollback-lines 10000 2>/dev/null || true
    if [ -f "$SCRIPT_DIR/config/gnome-console.dconf" ] && command -v dconf &>/dev/null; then
      dconf load /org/gnome/Console/ < "$SCRIPT_DIR/config/gnome-console.dconf" 2>/dev/null || true
    fi
    ok "GNOME Console configured."
  fi
elif [[ "$TERMINAL" == "ghostty" ]]; then
  mkdir -p "$HOME/.config/ghostty"
  if [ -f "$SCRIPT_DIR/config/ghostty.config" ]; then
    backup_file "$HOME/.config/ghostty/config"
    cp "$SCRIPT_DIR/config/ghostty.config" "$HOME/.config/ghostty/config"
    ok "Ghostty configured."
  fi
fi

ok "Configurations deployed."

# ── 8. Change Default Shell to Zsh ────────────────────────────────
ZSH_PATH="$(command -v zsh 2>/dev/null || true)"
if [ -n "$ZSH_PATH" ]; then
  CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    log "Setting default shell to zsh..."
    if grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
      chsh -s "$ZSH_PATH" || warn "Could not change default shell with chsh. Run: chsh -s $ZSH_PATH"
      ok "Default shell set to zsh (takes effect on next login)."
    else
      warn "$ZSH_PATH is not in /etc/shells. Add it with: echo $ZSH_PATH | sudo tee -a /etc/shells"
    fi
  else
    log "zsh is already the default shell."
  fi
fi

# ── 9. Import Shell History into Atuin ────────────────────────────
if command -v atuin &>/dev/null; then
  log "Importing history into Atuin..."
  atuin import auto 2>/dev/null || true
  ok "Atuin history setup complete."
fi

echo ""
echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
echo -e "${TEAL}${BOLD}│   ✓  Installation Complete!                        │${RESET}"
echo -e "${TEAL}│   Run: exec zsh   (or log out and back in)         │${RESET}"
echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
echo ""
