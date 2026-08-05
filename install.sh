#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Dotfiles Installer — Universal Linux Terminal Setup
#  Zsh + Oh My Zsh + Starship + Fastfetch
#  Supports: Arch Linux (paru/yay), Fedora Workstation (dnf)
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
    . /etc/os-release
    DISTRO_ID="${ID:-unknown}"
    DISTRO_LIKE="${ID_LIKE:-}"
  else
    DISTRO_ID="unknown"
    DISTRO_LIKE=""
  fi

  if [[ "$DISTRO_ID" == "arch" ]] || [[ "$DISTRO_LIKE" == *"arch"* ]]; then
    DISTRO="arch"
  elif [[ "$DISTRO_ID" == "fedora" ]] || [[ "$DISTRO_LIKE" == *"fedora"* ]]; then
    DISTRO="fedora"
  else
    warn "Unrecognized distro '$DISTRO_ID'. Attempting best-effort install."
    DISTRO="unknown"
  fi
  log "Detected distribution: ${BOLD}${DISTRO_ID}${RESET}"
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

# ── 2. Remove Conflicting Terminal ────────────────────────────────
remove_package() {
  local pkg="$1"
  case "$DISTRO" in
    arch)
      if pacman -Qi "$pkg" &>/dev/null; then
        paru -Rns --noconfirm "$pkg" 2>/dev/null || \
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
}

if [[ "$TERMINAL" == "gnome-console" ]]; then
  log "Removing Ghostty (if installed)..."
  remove_package "ghostty"
  [[ "$DISTRO" == "arch" ]] && remove_package "ghostty-shell-integration" && remove_package "ghostty-terminfo"
  rm -rf "$HOME/.config/ghostty" "$HOME/.local/share/ghostty" "$HOME/.cache/ghostty"
  ok "Ghostty removed and purged."
elif [[ "$TERMINAL" == "ghostty" ]]; then
  log "Removing GNOME Console (if installed)..."
  remove_package "gnome-console"
  ok "GNOME Console removed."
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
    error "No AUR helper found. Please install paru: https://github.com/Morganamilo/paru"
  fi
  log "Using AUR helper: ${BOLD}${AUR_HELPER}${RESET}"

  # Common packages
  $AUR_HELPER -S --noconfirm --needed \
    zsh starship fzf bat eza fd zoxide atuin ripgrep \
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols-mono \
    fastfetch

  # Terminal-specific
  if [[ "$TERMINAL" == "ghostty" ]]; then
    $AUR_HELPER -S --noconfirm --needed ghostty
  else
    $AUR_HELPER -S --noconfirm --needed gnome-console
  fi
}

install_fedora() {
  # Enable RPM Fusion (free) if not already enabled (needed for some packages)
  if ! rpm -q rpmfusion-free-release &>/dev/null; then
    log "Enabling RPM Fusion Free repository..."
    sudo dnf install -y \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
      2>/dev/null || warn "Could not enable RPM Fusion, some packages may be unavailable."
  fi

  # Common packages available in Fedora repos
  sudo dnf install -y \
    zsh fzf bat eza fd-find zoxide ripgrep \
    jetbrains-mono-fonts-all \
    fastfetch

  # Starship: install via official installer script (not in Fedora repos)
  if ! command -v starship &>/dev/null; then
    log "Installing Starship via official script..."
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  fi

  # Atuin: install via official installer script (Fedora COPR available but installer is easier)
  if ! command -v atuin &>/dev/null; then
    log "Installing Atuin via official script..."
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) || \
      warn "Atuin install failed, skipping."
  fi

  # Terminal-specific
  if [[ "$TERMINAL" == "ghostty" ]]; then
    # Ghostty is in Fedora official repos as of Fedora 42+
    if sudo dnf install -y ghostty 2>/dev/null; then
      ok "Ghostty installed via dnf."
    else
      warn "Ghostty not found in repos. Install manually: https://ghostty.org"
    fi
  else
    # gnome-console is bundled with GNOME, ensure it's installed
    sudo dnf install -y gnome-console 2>/dev/null || true
  fi
}

case "$DISTRO" in
  arch)    install_arch ;;
  fedora)  install_fedora ;;
  *)       warn "Unknown distro — skipping package installation. Install manually: zsh fzf bat eza fd zoxide atuin starship fastfetch" ;;
esac

ok "System packages installed."

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

clone_plugin "zsh-completions"              "https://github.com/zsh-completions/zsh-completions"        "$ZSH_CUSTOM/plugins/zsh-completions"
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

# Write distro-aware zshrc
DISTRO_VAR="$DISTRO" envsubst < "$SCRIPT_DIR/config/zshrc.template" > "$HOME/.zshrc" 2>/dev/null || \
  cp "$SCRIPT_DIR/config/zshrc" "$HOME/.zshrc"

# On Fedora, fd binary is named 'fd-find' — patch the zshrc alias
if [[ "$DISTRO" == "fedora" ]]; then
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    # Append fd alias for Fedora
    echo "" >> "$HOME/.zshrc"
    echo "# Fedora: fd-find binary is named fdfind" >> "$HOME/.zshrc"
    echo "alias fd='fdfind'" >> "$HOME/.zshrc"
  fi
fi

cp "$SCRIPT_DIR/config/starship.toml"   "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/config/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"

# ── 7. Configure Terminal ──────────────────────────────────────────
if [[ "$TERMINAL" == "gnome-console" ]]; then
  if command -v gsettings &>/dev/null; then
    log "Configuring GNOME Console..."
    gsettings set org.gnome.Console use-system-font false
    gsettings set org.gnome.Console custom-font 'JetBrainsMono Nerd Font 13'
    gsettings set org.gnome.Console theme 'night'
    gsettings set org.gnome.Console scrollback-lines 10000
    if [ -f "$SCRIPT_DIR/config/gnome-console.dconf" ] && command -v dconf &>/dev/null; then
      dconf load /org/gnome/Console/ < "$SCRIPT_DIR/config/gnome-console.dconf"
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
ZSH_PATH="$(command -v zsh)"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  log "Setting default shell to zsh..."
  chsh -s "$ZSH_PATH"
  ok "Default shell set to zsh (takes effect on next login)."
else
  log "zsh is already the default shell."
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
