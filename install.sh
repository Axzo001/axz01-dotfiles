#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Dotfiles Installer — Universal Linux Workstation Setup
#  Terminal │ Desktop & Extensions │ Productivity │ Media │ Wallpapers
#  Supports: Arch Linux (paru/yay/pacman), Fedora Workstation (dnf)
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

# ── Colors & UI ───────────────────────────────────────────────────
CYAN='\033[38;2;0;180;216m'; TEAL='\033[38;2;0;229;160m'
MINT='\033[38;2;77;255;210m'; RED='\033[0;31m'
BOLD='\033[1m'; RESET='\033[0m'

log()   { echo -e "${TEAL}${BOLD}❯${RESET} $*"; }
ok()    { echo -e "${MINT}${BOLD}✓${RESET} $*"; }
warn()  { echo -e "${CYAN}${BOLD}⚠${RESET} $*"; }
error() { echo -e "${RED}${BOLD}✗${RESET} $*"; exit 1; }
ask()   { echo -e "${TEAL}${BOLD}?${RESET} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISTRO="unknown"
DISTRO_ID="unknown"
AUR_HELPER=""
TERMINAL="gnome-console"

# ── 0. Distro Detection ───────────────────────────────────────────
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
    warn "Unrecognized distribution '$DISTRO_ID'. Defaulting to best-effort mode."
    DISTRO="unknown"
  fi
  log "Detected distribution: ${BOLD}${DISTRO_ID}${RESET} (profile: ${DISTRO})"
}

# ── 1. AUR Helper Setup (Arch Linux) ──────────────────────────────
setup_aur_helper() {
  [[ "$DISTRO" != "arch" ]] && return 0

  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    log "Found AUR helper: ${BOLD}paru${RESET}"
    return 0
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    log "Found AUR helper: ${BOLD}yay${RESET}"
    return 0
  fi

  echo ""
  warn "No AUR helper (paru/yay) was detected on your Arch system."
  ask "Which AUR helper would you like to build and install?"
  echo "  1) paru  (Rust-based, fast, modern — recommended)"
  echo "  2) yay   (Go-based, lightweight, classic)"
  echo "  3) None  (Use standard pacman for official packages only)"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1/2/3] (default: 1): " HELPER_CHOICE
  HELPER_CHOICE="${HELPER_CHOICE:-1}"

  case "$HELPER_CHOICE" in
    2)
      log "Installing dependencies for yay (base-devel, git, go)..."
      sudo pacman -S --needed --noconfirm base-devel git go
      local tmp_yay="/tmp/yay-install-$$"
      rm -rf "$tmp_yay"
      git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp_yay"
      (cd "$tmp_yay" && makepkg -si --noconfirm)
      rm -rf "$tmp_yay"
      AUR_HELPER="yay"
      ok "yay successfully installed and configured."
      ;;
    3)
      warn "Skipping AUR helper installation. AUR-only packages will be skipped."
      AUR_HELPER="sudo pacman"
      ;;
    *)
      log "Installing dependencies for paru (base-devel, git, rust, cargo)..."
      sudo pacman -S --needed --noconfirm base-devel git rust cargo
      local tmp_paru="/tmp/paru-install-$$"
      rm -rf "$tmp_paru"
      git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp_paru"
      (cd "$tmp_paru" && makepkg -si --noconfirm)
      rm -rf "$tmp_paru"
      AUR_HELPER="paru"
      ok "paru successfully installed and configured."
      ;;
  esac
}

# ── 2. Terminal Selection ─────────────────────────────────────────
choose_terminal() {
  echo ""
  ask "Which terminal do you want to configure?"
  echo "  1) GNOME Console  (default, clean GNOME integration)"
  echo "  2) Ghostty        (GPU-accelerated, modern splits & tabs)"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1/2] (default: 1): " TERM_CHOICE
  TERM_CHOICE="${TERM_CHOICE:-1}"

  case "$TERM_CHOICE" in
    2) TERMINAL="ghostty" ;;
    *) TERMINAL="gnome-console" ;;
  esac
  log "Selected terminal: ${BOLD}${TERMINAL}${RESET}"
}

# ── 3. Remove Conflicting Terminal (Optional) ──────────────────────
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

purge_alternate_terminal() {
  echo ""
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
      ok "Ghostty removed."
    elif [[ "$TERMINAL" == "ghostty" ]]; then
      log "Removing GNOME Console (if installed)..."
      remove_package "gnome-console"
      ok "GNOME Console removed."
    fi
  else
    log "Keeping alternate terminal installed."
  fi
}

# ── 4. System Packages & Tools ────────────────────────────────────
install_system_packages() {
  log "Installing base terminal packages and dependencies..."

  if [[ "$DISTRO" == "arch" ]]; then
    ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed \
      zsh starship fzf bat eza fd zoxide atuin ripgrep \
      ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols \
      fastfetch || warn "Some Arch packages failed to install, continuing..."

    if [[ "$TERMINAL" == "ghostty" ]]; then
      ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed ghostty || warn "Could not install Ghostty."
    else
      ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-console || true
    fi

  elif [[ "$DISTRO" == "fedora" ]]; then
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
      log "Enabling RPM Fusion Free..."
      sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        2>/dev/null || warn "Could not enable RPM Fusion."
    fi

    sudo dnf install -y \
      zsh fzf bat eza fd-find zoxide ripgrep fastfetch curl \
      jetbrains-mono-fonts 2>/dev/null || warn "Some dnf packages failed to install."

    # Install JetBrainsMono Nerd Font if not present
    if ! fc-list : family 2>/dev/null | grep -iq "JetBrainsMono Nerd Font"; then
      log "Downloading JetBrainsMono Nerd Font for Fedora..."
      local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
      mkdir -p "$font_dir"
      if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz" -o /tmp/JetBrainsMono.tar.xz; then
        tar -xf /tmp/JetBrainsMono.tar.xz -C "$font_dir"
        rm -f /tmp/JetBrainsMono.tar.xz
        fc-cache -f "$font_dir" 2>/dev/null || true
        ok "JetBrainsMono Nerd Font installed to ~/.local/share/fonts."
      fi
    fi

    # Symlink fd -> fdfind
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi

    # Starship
    if ! command -v starship &>/dev/null; then
      sudo dnf install -y starship 2>/dev/null || \
        (curl -sS https://starship.rs/install.sh | sh -s -- --yes) || true
    fi

    # Atuin
    if ! command -v atuin &>/dev/null; then
      sudo dnf install -y atuin 2>/dev/null || \
        (bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)) || true
    fi

    # Terminal
    if [[ "$TERMINAL" == "ghostty" ]]; then
      sudo dnf install -y ghostty 2>/dev/null || warn "Ghostty not found in repos. Install via ghostty.org"
    else
      sudo dnf install -y gnome-console 2>/dev/null || true
    fi
  fi
  ok "Base dependencies processed."
}

# ── 5. Oh My Zsh & Plugins ────────────────────────────────────────
install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    log "Installing Oh My Zsh..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
    ok "Oh My Zsh installed."
  else
    ok "Oh My Zsh already installed."
  fi
}

clone_plugin() {
  local name="$1" url="$2" dest="$3"
  if [ ! -d "$dest" ]; then
    log "Cloning plugin: ${BOLD}$name${RESET}..."
    git clone --depth=1 "$url" "$dest"
    ok "$name cloned."
  else
    warn "$name already exists — updating..."
    git -C "$dest" pull --ff-only --quiet 2>/dev/null || true
  fi
}

clone_omz_plugins() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  clone_plugin "zsh-completions"              "https://github.com/zsh-users/zsh-completions"              "$zsh_custom/plugins/zsh-completions"
  clone_plugin "fzf-tab"                      "https://github.com/Aloxaf/fzf-tab"                         "$zsh_custom/plugins/fzf-tab"
  clone_plugin "you-should-use"               "https://github.com/MichaelAquilina/zsh-you-should-use"     "$zsh_custom/plugins/you-should-use"
  clone_plugin "zsh-autosuggestions"          "https://github.com/zsh-users/zsh-autosuggestions"          "$zsh_custom/plugins/zsh-autosuggestions"
  clone_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search" "$zsh_custom/plugins/zsh-history-substring-search"
  clone_plugin "zsh-syntax-highlighting"      "https://github.com/zsh-users/zsh-syntax-highlighting"      "$zsh_custom/plugins/zsh-syntax-highlighting"
}

# ── 6. Deploy Configs ─────────────────────────────────────────────
backup_file() {
  local file="$1"
  if [ -f "$file" ] && [ ! -L "$file" ]; then
    warn "Backing up: $file → ${file}.bak"
    cp "$file" "${file}.bak"
  fi
}

deploy_configs() {
  log "Deploying configuration files..."
  mkdir -p "$HOME/.config/fastfetch"

  backup_file "$HOME/.zshrc"
  backup_file "$HOME/.config/starship.toml"
  backup_file "$HOME/.config/fastfetch/config.jsonc"

  cp "$SCRIPT_DIR/config/zshrc"          "$HOME/.zshrc"
  cp "$SCRIPT_DIR/config/starship.toml"   "$HOME/.config/starship.toml"
  cp "$SCRIPT_DIR/config/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"

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
}

# ── 7. Shell & Atuin Setup ────────────────────────────────────────
change_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh 2>/dev/null || true)"
  if [ -n "$zsh_path" ]; then
    local current_shell
    current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")"
    if [ "$current_shell" != "$zsh_path" ]; then
      log "Setting default login shell to zsh..."
      if grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
        chsh -s "$zsh_path" || warn "Could not change default shell with chsh. Run: chsh -s $zsh_path"
        ok "Default shell set to zsh (active on next login)."
      else
        warn "$zsh_path is not listed in /etc/shells."
      fi
    else
      ok "zsh is already your default shell."
    fi
  fi
}

setup_atuin_history() {
  if command -v atuin &>/dev/null; then
    log "Importing shell history into Atuin..."
    atuin import auto 2>/dev/null || true
    ok "Atuin setup complete."
  fi
}

# ── 8. Hatter Icon Theme (Mibea/Hatter) ────────────────────────────
install_hatter_icons() {
  log "Installing Hatter Icon Theme (https://github.com/Mibea/Hatter)..."
  local icon_dir="$HOME/.icons"
  mkdir -p "$icon_dir"
  local tmp_dir="/tmp/hatter-icons-$$"
  rm -rf "$tmp_dir"

  if git clone --depth=1 https://github.com/Mibea/Hatter.git "$tmp_dir"; then
    log "Copying Hatter icon packs directly to ~/.icons/..."
    local copied_any=false
    for d in "$tmp_dir"/Hatter*/; do
      if [ -d "$d" ] && [ -f "$d/index.theme" ]; then
        local theme_name
        theme_name="$(basename "$d")"
        rm -rf "$icon_dir/$theme_name"
        cp -r "$d" "$icon_dir/"
        gtk-update-icon-cache -f "$icon_dir/$theme_name" 2>/dev/null || true
        copied_any=true
      fi
    done

    # Clean up cloned repo
    rm -rf "$tmp_dir"

    if [ "$copied_any" = true ]; then
      if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface icon-theme 'Hatter' 2>/dev/null || true
        ok "Hatter Icon Theme set as active GNOME icon theme."
      fi
      ok "Hatter icon packs successfully installed to ~/.icons/."
    else
      warn "No Hatter icon directories found in the cloned repository."
    fi
  else
    warn "Could not clone Hatter repository. Please check your internet connection."
  fi
}

# ── 9. GNOME Extensions & Extension Manager ───────────────────────
install_extension_manager() {
  log "Installing Extension Manager (GUI)..."
  if command -v extension-manager &>/dev/null || (command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "com.mattjakeman.ExtensionManager"); then
    ok "Extension Manager is already installed."
    return 0
  fi

  if [[ "$DISTRO" == "arch" ]]; then
    ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed extension-manager 2>/dev/null || \
      ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-shell-extension-manager 2>/dev/null || \
      (flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || warn "Extension Manager install failed.")
  elif [[ "$DISTRO" == "fedora" ]]; then
    sudo dnf install -y extension-manager 2>/dev/null || \
      (flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || warn "Extension Manager install failed.")
  else
    if command -v flatpak &>/dev/null; then
      flatpak install -y flathub com.mattjakeman.ExtensionManager 2>/dev/null || warn "Extension Manager install failed."
    fi
  fi
  ok "Extension Manager processed."
}

configure_gsconnect_firewall() {
  log "Configuring firewall for GSConnect (ports 1714-1764 TCP/UDP)..."
  local fw_configured=false

  # 1. firewalld (default on Fedora, common on Arch)
  if command -v firewall-cmd &>/dev/null; then
    if systemctl is-active --quiet firewalld 2>/dev/null || firewall-cmd --state &>/dev/null; then
      log "Adding GSConnect / KDE Connect rules to firewalld..."
      sudo firewall-cmd --permanent --zone=public --add-service=kdeconnect 2>/dev/null || \
        sudo firewall-cmd --permanent --add-port=1714-1764/tcp --add-port=1714-1764/udp 2>/dev/null || true
      sudo firewall-cmd --reload 2>/dev/null || true
      fw_configured=true
      ok "firewalld rules configured for GSConnect."
    fi
  fi

  # 2. UFW (Uncomplicated Firewall)
  if command -v ufw &>/dev/null; then
    if sudo ufw status 2>/dev/null | grep -qw "active"; then
      log "Adding GSConnect rules to UFW..."
      sudo ufw allow 1714:1764/tcp comment 'GSConnect' 2>/dev/null || true
      sudo ufw allow 1714:1764/udp comment 'GSConnect' 2>/dev/null || true
      sudo ufw reload 2>/dev/null || true
      fw_configured=true
      ok "UFW rules configured for GSConnect."
    fi
  fi

  if [ "$fw_configured" = false ]; then
    log "No active firewall (firewalld/ufw) detected. Ports 1714-1764 TCP/UDP are open by default."
  fi
}

install_gnome_extension_by_uuid() {
  local uuid="$1"
  local name="$2"
  log "Installing GNOME extension: ${BOLD}$name${RESET} ($uuid)..."

  # Check if already installed & enabled
  if command -v gnome-extensions &>/dev/null; then
    if gnome-extensions list 2>/dev/null | grep -q "$uuid"; then
      gnome-extensions enable "$uuid" 2>/dev/null || true
      if [[ "$uuid" == "gsconnect@andyholmes.github.io" ]]; then
        configure_gsconnect_firewall
      fi
      ok "$name is already installed and enabled."
      return 0
    fi
  fi

  # Determine GNOME shell version
  local gver="47"
  if command -v gnome-shell &>/dev/null; then
    gver="$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1 || echo "47")"
  fi

  # 1. Download directly from extensions.gnome.org API
  local dl_url
  dl_url="$(curl -sS "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${gver}" 2>/dev/null | grep -oP '"download_url":\s*"\K[^"]+' || true)"
  
  if [ -n "$dl_url" ]; then
    local tmp_zip="/tmp/${uuid}-$$.zip"
    if curl -fsSL "https://extensions.gnome.org${dl_url}" -o "$tmp_zip"; then
      if command -v gnome-extensions &>/dev/null; then
        gnome-extensions install --force "$tmp_zip" 2>/dev/null || true
        gnome-extensions enable "$uuid" 2>/dev/null || true
      else
        mkdir -p "$HOME/.local/share/gnome-shell/extensions/$uuid"
        unzip -qo "$tmp_zip" -d "$HOME/.local/share/gnome-shell/extensions/$uuid" 2>/dev/null || true
      fi
      rm -f "$tmp_zip"
      if [[ "$uuid" == "gsconnect@andyholmes.github.io" ]]; then
        configure_gsconnect_firewall
      fi
      ok "$name installed from GNOME Extensions repository."
      return 0
    fi
  fi

  # 2. Distro package fallback
  if [[ "$DISTRO" == "arch" ]]; then
    case "$uuid" in
      "appindicatorsupport@rgcjonas.gmail.com")
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-shell-extension-appindicator 2>/dev/null || true ;;
      "blur-my-shell@aunetx")
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-shell-extension-blur-my-shell 2>/dev/null || true ;;
      "caffeine@patapon.info")
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-shell-extension-caffeine 2>/dev/null || true ;;
      "gsconnect@andyholmes.github.io")
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-shell-extension-gsconnect 2>/dev/null || true ;;
      "just-perfection-desktop@just-perfection")
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed gnome-shell-extension-just-perfection 2>/dev/null || true ;;
    esac
  elif [[ "$DISTRO" == "fedora" ]]; then
    case "$uuid" in
      "appindicatorsupport@rgcjonas.gmail.com")
        sudo dnf install -y gnome-shell-extension-appindicator 2>/dev/null || true ;;
      "caffeine@patapon.info")
        sudo dnf install -y gnome-shell-extension-caffeine 2>/dev/null || true ;;
      "gsconnect@andyholmes.github.io")
        sudo dnf install -y gnome-shell-extension-gsconnect 2>/dev/null || true ;;
    esac
  fi

  if command -v gnome-extensions &>/dev/null; then
    gnome-extensions enable "$uuid" 2>/dev/null || true
  fi
  if [[ "$uuid" == "gsconnect@andyholmes.github.io" ]]; then
    configure_gsconnect_firewall
  fi
  ok "$name processed."
}

install_gnome_extensions_suite() {
  echo ""
  echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
  echo -e "${TEAL}${BOLD}│         GNOME Extensions & Extension Manager       │${RESET}"
  echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
  
  install_extension_manager

  echo ""
  echo "Recommended GNOME Extensions:"
  echo "  1) AppIndicator and KStatusNotifierItem Support"
  echo "  2) Blur my Shell"
  echo "  3) Caffeine"
  echo "  4) GSConnect"
  echo "  5) Just Perfection"
  echo "  6) Install All Extensions (recommended)"
  echo "  0) Skip Extensions"
  echo ""
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1-6 / 0] (default: 6): " EXT_CHOICE
  EXT_CHOICE="${EXT_CHOICE:-6}"

  [[ "$EXT_CHOICE" == "0" ]] && return 0

  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.shell disable-user-extensions false 2>/dev/null || true
  fi

  if [[ "$EXT_CHOICE" == "1" || "$EXT_CHOICE" == "6" ]]; then
    install_gnome_extension_by_uuid "appindicatorsupport@rgcjonas.gmail.com" "AppIndicator Support"
  fi
  if [[ "$EXT_CHOICE" == "2" || "$EXT_CHOICE" == "6" ]]; then
    install_gnome_extension_by_uuid "blur-my-shell@aunetx" "Blur my Shell"
  fi
  if [[ "$EXT_CHOICE" == "3" || "$EXT_CHOICE" == "6" ]]; then
    install_gnome_extension_by_uuid "caffeine@patapon.info" "Caffeine"
  fi
  if [[ "$EXT_CHOICE" == "4" || "$EXT_CHOICE" == "6" ]]; then
    install_gnome_extension_by_uuid "gsconnect@andyholmes.github.io" "GSConnect"
  fi
  if [[ "$EXT_CHOICE" == "5" || "$EXT_CHOICE" == "6" ]]; then
    install_gnome_extension_by_uuid "just-perfection-desktop@just-perfection" "Just Perfection"
  fi

  ok "GNOME Extensions setup complete (log out and back in to apply Shell changes)."
}

# ── 10. Productivity Suite ────────────────────────────────────────
install_productivity_apps() {
  echo ""
  echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
  echo -e "${TEAL}${BOLD}│       Productivity & Developer Applications       │${RESET}"
  echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
  echo "  1) Zed Editor"
  echo "  2) Google Antigravity & Antigravity CLI"
  echo "  3) Android Studio"
  echo "  4) ONLYOFFICE Desktop Editors"
  echo "  5) Install All Productivity Apps (recommended)"
  echo "  0) Skip"
  echo ""
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1-5 / 0]: " APP_CHOICE
  APP_CHOICE="${APP_CHOICE:-5}"

  [[ "$APP_CHOICE" == "0" ]] && return 0

  # Zed Editor
  if [[ "$APP_CHOICE" == "1" || "$APP_CHOICE" == "5" ]]; then
    log "Installing Zed Editor..."
    if command -v zed &>/dev/null; then
      ok "Zed is already installed."
    elif [[ "$DISTRO" == "arch" ]]; then
      ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed zed-editor 2>/dev/null || \
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed zed 2>/dev/null || \
        curl -f https://zed.dev/install.sh | sh
      ok "Zed installed."
    elif [[ "$DISTRO" == "fedora" ]]; then
      curl -f https://zed.dev/install.sh | sh 2>/dev/null || \
        (flatpak install -y flathub dev.zed.Zed 2>/dev/null || warn "Zed install failed.")
      ok "Zed installed."
    fi
  fi

  # Google Antigravity & Antigravity CLI
  if [[ "$APP_CHOICE" == "2" || "$APP_CHOICE" == "5" ]]; then
    log "Installing Google Antigravity & CLI..."
    if command -v agy &>/dev/null || command -v antigravity &>/dev/null; then
      ok "Antigravity is already installed."
    else
      if [[ "$DISTRO" == "arch" ]]; then
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed antigravity-bin 2>/dev/null || \
          ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed antigravity 2>/dev/null || true
      fi
      if ! command -v agy &>/dev/null && ! command -v antigravity &>/dev/null; then
        curl -fsSL https://antigravity.google/install.sh 2>/dev/null | bash 2>/dev/null || \
          warn "Please visit https://antigravity.google to download Antigravity."
      fi
      ok "Antigravity processed."
    fi
  fi

  # Android Studio
  if [[ "$APP_CHOICE" == "3" || "$APP_CHOICE" == "5" ]]; then
    log "Installing Android Studio..."
    if command -v android-studio &>/dev/null || (command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "com.google.AndroidStudio"); then
      ok "Android Studio is already installed."
    elif [[ "$DISTRO" == "arch" ]]; then
      ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed android-studio 2>/dev/null || \
        (flatpak install -y flathub com.google.AndroidStudio 2>/dev/null || warn "Android Studio install failed.")
      ok "Android Studio installed."
    elif [[ "$DISTRO" == "fedora" ]]; then
      flatpak install -y flathub com.google.AndroidStudio 2>/dev/null || \
        warn "Could not install Android Studio. Install via Flatpak or developer.android.com"
    fi
  fi

  # ONLYOFFICE
  if [[ "$APP_CHOICE" == "4" || "$APP_CHOICE" == "5" ]]; then
    log "Installing ONLYOFFICE Desktop Editors..."
    if command -v onlyoffice-desktopeditors &>/dev/null || (command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "org.onlyoffice.desktopeditors"); then
      ok "ONLYOFFICE is already installed."
    elif [[ "$DISTRO" == "arch" ]]; then
      ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed onlyoffice-bin 2>/dev/null || \
        (flatpak install -y flathub org.onlyoffice.desktopeditors 2>/dev/null || warn "ONLYOFFICE install failed.")
      ok "ONLYOFFICE installed."
    elif [[ "$DISTRO" == "fedora" ]]; then
      flatpak install -y flathub org.onlyoffice.desktopeditors 2>/dev/null || \
        sudo dnf install -y onlyoffice-desktopeditors 2>/dev/null || \
        warn "ONLYOFFICE install failed."
    fi
  fi
}

# ── 11. Spotify & SpotX-Bash ──────────────────────────────────────
install_spotify_and_spotx() {
  echo ""
  echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
  echo -e "${TEAL}${BOLD}│         Spotify & SpotX-Bash Adblock Patcher       │${RESET}"
  echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
  log "Installing Spotify & SpotX-Bash (Adblock & Feature Patcher)..."

  # 1. Check/Install Spotify
  if command -v spotify &>/dev/null || (command -v flatpak &>/dev/null && flatpak list 2>/dev/null | grep -q "com.spotify.Client"); then
    ok "Spotify is already installed."
  else
    log "Installing Spotify client..."
    if [[ "$DISTRO" == "arch" ]]; then
      if pacman -Si spotify-launcher &>/dev/null; then
        sudo pacman -S --noconfirm --needed spotify-launcher 2>/dev/null || \
          ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed spotify 2>/dev/null || \
          (flatpak install -y flathub com.spotify.Client 2>/dev/null || warn "Spotify install failed.")
      else
        ${AUR_HELPER:-sudo pacman} -S --noconfirm --needed spotify 2>/dev/null || \
          (flatpak install -y flathub com.spotify.Client 2>/dev/null || warn "Spotify install failed.")
      fi
      ok "Spotify installed."
    elif [[ "$DISTRO" == "fedora" ]]; then
      if command -v flatpak &>/dev/null; then
        flatpak install -y flathub com.spotify.Client 2>/dev/null || warn "Spotify Flatpak install failed."
      else
        sudo dnf install -y lpf-spotify-client 2>/dev/null || warn "Spotify install failed."
      fi
      ok "Spotify installed."
    fi
  fi

  # 2. Run SpotX-Bash patcher
  echo ""
  ask "Do you want to run SpotX-Bash now to block ads and unlock features? [Y/n]"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [Y/n] (default: Y): " RUN_SPOTX
  RUN_SPOTX="${RUN_SPOTX:-Y}"

  if [[ "$RUN_SPOTX" =~ ^[Yy]$ ]]; then
    log "Running SpotX-Bash patcher..."
    bash <(curl -sSL https://raw.githubusercontent.com/SpotX-Official/SpotX-Bash/main/spotx.sh) || \
      bash <(curl -sSL https://spotx-official.github.io/run.sh) || \
      warn "SpotX-Bash execution failed. Please run manually: bash <(curl -sSL https://spotx-official.github.io/run.sh)"
    ok "SpotX-Bash executed."
  fi
}

# ── 12. Workstation Wallpapers ────────────────────────────────────
install_wallpapers() {
  echo ""
  echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────╮${RESET}"
  echo -e "${TEAL}${BOLD}│                Workstation Wallpapers              │${RESET}"
  echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────╯${RESET}"
  log "Installing wallpapers to ~/Pictures/Wallpapers/..."
  local wp_dir="$HOME/Pictures/Wallpapers"
  mkdir -p "$wp_dir"

  if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    cp -r "$SCRIPT_DIR/wallpapers/"* "$wp_dir/" 2>/dev/null || true
    ok "Wallpapers copied to $wp_dir."
  fi

  echo ""
  ask "Which wallpaper would you like to set as active desktop background?"
  echo "  1) Creation of Adam (Matrix Dots)"
  echo "  2) Arch Linux Monochrome Cubes"
  echo "  3) Keep current wallpaper"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1-3] (default: 1): " WP_CHOICE
  WP_CHOICE="${WP_CHOICE:-1}"

  local selected_wp=""
  case "$WP_CHOICE" in
    1) selected_wp="$wp_dir/creation-of-adam.jpg" ;;
    2) selected_wp="$wp_dir/arch-cubes.jpg" ;;
    *) log "Keeping current wallpaper." ;;
  esac

  if [ -n "$selected_wp" ] && [ -f "$selected_wp" ]; then
    if command -v gsettings &>/dev/null; then
      gsettings set org.gnome.desktop.background picture-uri "file://$selected_wp" 2>/dev/null || true
      gsettings set org.gnome.desktop.background picture-uri-dark "file://$selected_wp" 2>/dev/null || true
      gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null || true
      ok "Wallpaper applied to GNOME Desktop."
    fi
  fi
}

# ── Complete Setup Workflow ───────────────────────────────────────
run_terminal_setup() {
  setup_aur_helper
  choose_terminal
  purge_alternate_terminal
  install_system_packages
  install_oh_my_zsh
  clone_omz_plugins
  deploy_configs
  change_default_shell
  setup_atuin_history
}

run_desktop_setup() {
  install_hatter_icons
  install_wallpapers
}

run_full_setup() {
  run_terminal_setup
  
  echo ""
  ask "Do you want to install Hatter Icons & Custom Wallpapers? [Y/n]"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [Y/n] (default: Y): " DO_DESKTOP
  DO_DESKTOP="${DO_DESKTOP:-Y}"
  [[ "$DO_DESKTOP" =~ ^[Yy]$ ]] && run_desktop_setup

  echo ""
  ask "Do you want to install Extension Manager and GNOME Extensions? [Y/n]"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [Y/n] (default: Y): " DO_EXTS
  DO_EXTS="${DO_EXTS:-Y}"
  [[ "$DO_EXTS" =~ ^[Yy]$ ]] && install_gnome_extensions_suite

  echo ""
  ask "Do you want to install Productivity & Dev Apps (Zed, Antigravity, Android Studio, ONLYOFFICE)? [Y/n]"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [Y/n] (default: Y): " DO_APPS
  DO_APPS="${DO_APPS:-Y}"
  [[ "$DO_APPS" =~ ^[Yy]$ ]] && install_productivity_apps

  echo ""
  ask "Do you want to install Spotify and apply SpotX-Bash adblock patch? [Y/n]"
  read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [Y/n] (default: Y): " DO_SPOTIFY
  DO_SPOTIFY="${DO_SPOTIFY:-Y}"
  [[ "$DO_SPOTIFY" =~ ^[Yy]$ ]] && install_spotify_and_spotx
}

# ── Main Menu ─────────────────────────────────────────────────────
detect_distro

echo ""
echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────────╮${RESET}"
echo -e "${TEAL}${BOLD}│          Axzo001 Dotfiles — Master Installer           │${RESET}"
echo -e "${TEAL}${BOLD}│   Terminal │ Desktop & Wallpapers │ Apps │ Media       │${RESET}"
echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────────╯${RESET}"
echo ""
echo "Select installation mode:"
echo "  1) Full Workstation Setup (Terminal + Configs + Desktop + Extensions + Apps + Spotify)"
echo "  2) Terminal Setup Only    (Zsh, Starship, Fastfetch, Atuin, Ghostty/Console)"
echo "  3) Desktop & Wallpapers   (Hatter Icon Theme + Dark Monochrome Wallpapers)"
echo "  4) GNOME Extensions Suite (Extension Manager GUI + Top 5 GNOME Extensions)"
echo "  5) Productivity Suite     (Zed, Antigravity, Android Studio, ONLYOFFICE)"
echo "  6) Spotify & SpotX-Bash   (Spotify Desktop + SpotX Adblock/Theme Patcher)"
echo "  7) Deploy Configs Only    (Sync .zshrc, starship.toml, fastfetch, terminal)"
echo "  0) Exit"
echo ""
read -rp "$(echo -e "${TEAL}${BOLD}  ❯ ${RESET}")Enter choice [1-7 / 0] (default: 1): " MENU_CHOICE
MENU_CHOICE="${MENU_CHOICE:-1}"

case "$MENU_CHOICE" in
  1) run_full_setup ;;
  2) run_terminal_setup ;;
  3) run_desktop_setup ;;
  4)
    setup_aur_helper
    install_gnome_extensions_suite
    ;;
  5)
    setup_aur_helper
    install_productivity_apps
    ;;
  6)
    setup_aur_helper
    install_spotify_and_spotx
    ;;
  7)
    choose_terminal
    deploy_configs
    ;;
  0)
    log "Exiting installer."
    exit 0
    ;;
  *)
    warn "Invalid choice, running Full Workstation Setup."
    run_full_setup
    ;;
esac

echo ""
echo -e "${TEAL}${BOLD}╭────────────────────────────────────────────────────────╮${RESET}"
echo -e "${TEAL}${BOLD}│   ✓  Installation Complete!                            │${RESET}"
echo -e "${TEAL}│   Run: exec zsh   (or log out and back in)             │${RESET}"
echo -e "${TEAL}${BOLD}╰────────────────────────────────────────────────────────╯${RESET}"
echo ""
