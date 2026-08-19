#!/usr/bin/env bash
# Instalação completa em máquina nova (Arch + dotfiles).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
RESET='\033[0m'

echo -e "${BLUE}=== Barista Dots — install ===${RESET}"

if [[ "$EUID" -eq 0 ]]; then
  echo -e "${RED}[!] Não rode como root.${RESET}"
  exit 1
fi

# yay
if ! command -v yay >/dev/null 2>&1; then
  echo -e "${BLUE}[*] Instalando yay...${RESET}"
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build
  (cd /tmp/yay-build && makepkg -si --noconfirm)
else
  echo -e "${GREEN}[v] yay ok${RESET}"
fi

# Pacotes essenciais primeiro (stack atual: Hyprland + DMS)
ESSENTIAL=(
  hyprland hypridle hyprlock hyprpolkitagent
  dms-shell dms-shell-hyprland foot tmux fuzzel zsh
  pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber
  networkmanager bluez bluez-utils
  grim slurp wl-clipboard cliphist
  starship fastfetch btop cava yazi neovim
  noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
  catppuccin-gtk-theme-macchiato catppuccin-cursors-macchiato
  ly udiskie jq ripgrep fd
)

echo -e "${BLUE}[*] Pacotes essenciais...${RESET}"
for pkg in "${ESSENTIAL[@]}"; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    yay -S --needed --noconfirm "$pkg" || echo -e "${RED}[!] falhou: $pkg${RESET}"
  fi
done

# Restante do packages.txt (opcional, ignora erros)
if [[ -f "$DOTFILES/packages.txt" ]]; then
  echo -e "${BLUE}[*] Pacotes de packages.txt...${RESET}"
  while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    pacman -Qi "$pkg" &>/dev/null && continue
    yay -S --needed --noconfirm "$pkg" || echo -e "${RED}[!] falhou: $pkg${RESET}"
  done < "$DOTFILES/packages.txt"
fi

# Aplicar dotfiles (symlinks)
"$DOTFILES/apply.sh"

# Session manager (ly@tty1 ou DMS greeter — NÃO usar "systemctl enable ly")
echo -e "${BLUE}[*] Session manager...${RESET}"
"$DOTFILES/hooks/setup-session.sh"

# Serviços de sistema
echo -e "${BLUE}[*] Serviços systemd (system)...${RESET}"
for svc in NetworkManager bluetooth docker cronie tlp ufw cups; do
  sudo -A systemctl enable "$svc" 2>/dev/null || true
done

# Shell padrão (só se zsh existir — evita "failed to initialize user" no Ly)
if command -v zsh >/dev/null 2>&1; then
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  ZSH_PATH="$(command -v zsh)"
  if [[ "$CURRENT_SHELL" != "$ZSH_PATH" && -x "$ZSH_PATH" ]]; then
    echo -e "${BLUE}[*] Definindo zsh como shell padrão...${RESET}"
    sudo -A chsh -s "$ZSH_PATH" "$USER" || true
  fi
else
  echo -e "${RED}[!] zsh não instalado — mantendo shell atual (importante pro Ly)${RESET}"
fi

"$DOTFILES/hooks/validate-login.sh" || true

echo -e "${GREEN}=== Instalação concluída ===${RESET}"
echo "Reinicie a sessão. Depois de git pull use: ~/dotfiles/update.sh"
