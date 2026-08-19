#!/usr/bin/env bash
# Instalação completa em máquina nova (Arch + dotfiles).
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
YELLOW='\033[33m'
RESET='\033[0m'

INSTALL_EXTRAS=0
INSTALL_MINIMAL=0

usage() {
  cat <<EOF
Uso: ./install.sh [opções]

  (sem flags)   core packages + apply + session + doctor
  --extras      instala também packages/extras.txt
  --minimal     só core, não altera shell padrão (chsh)
  -h, --help    esta ajuda
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --extras) INSTALL_EXTRAS=1; shift ;;
    --minimal) INSTALL_MINIMAL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1"; usage; exit 1 ;;
  esac
done

install_pkg_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  echo -e "${BLUE}[*] Pacotes de $(basename "$file")...${RESET}"
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    if ! pacman -Qi "$pkg" &>/dev/null; then
      yay -S --needed --noconfirm "$pkg" || echo -e "${YELLOW}[!] falhou: $pkg${RESET}"
    fi
  done < "$file"
}

echo -e "${BLUE}=== Barista Dots — install ===${RESET}"

if [[ "$EUID" -eq 0 ]]; then
  echo -e "${RED}[!] Não rode como root.${RESET}"
  exit 1
fi

if ! command -v yay >/dev/null 2>&1; then
  echo -e "${BLUE}[*] Instalando yay...${RESET}"
  sudo pacman -S --needed --noconfirm git base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build
  (cd /tmp/yay-build && makepkg -si --noconfirm)
else
  echo -e "${GREEN}[v] yay ok${RESET}"
fi

install_pkg_file "$DOTFILES/packages/core.txt"
if [[ "$INSTALL_EXTRAS" -eq 1 ]]; then
  install_pkg_file "$DOTFILES/packages/extras.txt"
fi

"$DOTFILES/apply.sh"

echo -e "${BLUE}[*] Session manager...${RESET}"
"$DOTFILES/hooks/setup-session.sh"

echo -e "${BLUE}[*] Serviços systemd (system)...${RESET}"
for svc in NetworkManager bluetooth; do
  sudo -A systemctl enable "$svc" 2>/dev/null || true
done

if [[ "$INSTALL_EXTRAS" -eq 1 ]]; then
  for svc in docker cronie tlp ufw cups; do
    sudo -A systemctl enable "$svc" 2>/dev/null || true
  done
fi

if [[ "$INSTALL_MINIMAL" -eq 0 ]] && command -v zsh >/dev/null 2>&1; then
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  ZSH_PATH="$(command -v zsh)"
  if [[ "$CURRENT_SHELL" != "$ZSH_PATH" && -x "$ZSH_PATH" ]]; then
    echo -e "${BLUE}[*] Definindo zsh como shell padrão...${RESET}"
    sudo -A chsh -s "$ZSH_PATH" "$USER" || true
  fi
elif [[ "$INSTALL_MINIMAL" -eq 0 ]]; then
  echo -e "${YELLOW}[!] zsh não instalado — mantendo shell atual${RESET}"
fi

"$DOTFILES/hooks/validate-login.sh" || true
"$DOTFILES/doctor.sh" || true

echo -e "${GREEN}=== Instalação concluída ===${RESET}"
echo "Reinicie. Depois de git pull: ~/dotfiles/update.sh"
echo "Debug: ~/dotfiles/doctor.sh"
