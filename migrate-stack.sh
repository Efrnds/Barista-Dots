#!/usr/bin/env bash
# Migra Hyprland+Foot+Yazi → niri+DMS+Alacritty+Thunar
# Instala core novo, remove obsolete.txt, apply + session + doctor.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN='\033[32m'
RED='\033[31m'
BLUE='\033[34m'
YELLOW='\033[33m'
RESET='\033[0m'

SKIP_REMOVE=0
YES=0

usage() {
  cat <<EOF
Uso: ./migrate-stack.sh [opções]

  Migra o desktop para a stack oficial:
    niri + DMS + Alacritty + Thunar

  --yes         não pedir confirmação
  --keep-old    não remove pacotes de packages/obsolete.txt
  -h, --help    esta ajuda

Depois de migrar, no Ly escolha a sessão **Niri (DMS)** e reinicie.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes|-y) YES=1; shift ;;
    --keep-old) SKIP_REMOVE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opção desconhecida: $1"; usage; exit 1 ;;
  esac
done

if [[ "$EUID" -eq 0 ]]; then
  echo -e "${RED}[!] Não rode como root.${RESET}"
  exit 1
fi

if ! command -v yay >/dev/null 2>&1; then
  echo -e "${RED}[!] yay necessário.${RESET}"
  exit 1
fi

echo -e "${BLUE}=== Barista Dots — migrate-stack (niri) ===${RESET}"
echo "Repo: $DOTFILES"
echo
echo "Vai instalar packages/core.txt e (salvo --keep-old) remover obsolete.txt."
if [[ "$YES" -eq 0 ]]; then
  read -r -p "Continuar? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "Abortado."; exit 1; }
fi

install_pkg_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  echo -e "${BLUE}[*] Instalando $(basename "$file")...${RESET}"
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    if ! pacman -Qi "$pkg" &>/dev/null; then
      yay -S --needed --noconfirm "$pkg" || echo -e "${YELLOW}[!] falhou: $pkg${RESET}"
    else
      echo -e "${GREEN}[v]${RESET} $pkg"
    fi
  done < "$file"
}

remove_obsolete() {
  local file="$DOTFILES/packages/obsolete.txt"
  [[ -f "$file" ]] || return 0
  local to_remove=()
  while read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    if pacman -Qi "$pkg" &>/dev/null; then
      to_remove+=("$pkg")
    fi
  done < "$file"
  if [[ ${#to_remove[@]} -eq 0 ]]; then
    echo -e "${GREEN}[v] nenhum pacote obsolete instalado${RESET}"
    return 0
  fi
  echo -e "${BLUE}[*] Removendo: ${to_remove[*]}${RESET}"
  # -Rns pode falhar por deps; tenta um a um
  for pkg in "${to_remove[@]}"; do
    sudo pacman -Rns --noconfirm "$pkg" 2>/dev/null \
      || sudo pacman -Rdd --noconfirm "$pkg" 2>/dev/null \
      || echo -e "${YELLOW}[!] não removeu: $pkg${RESET}"
  done
}

# 1) pull opcional se for update path
if [[ "${MIGRATE_SKIP_PULL:-0}" != "1" ]] && [[ -d "$DOTFILES/.git" ]]; then
  echo -e "${BLUE}[*] git pull...${RESET}"
  git -C "$DOTFILES" pull --rebase --autostash || true
fi

# 2) install new stack first (so remove doesn't leave you without a compositor)
install_pkg_file "$DOTFILES/packages/core.txt"

# 3) remove old
if [[ "$SKIP_REMOVE" -eq 0 ]]; then
  remove_obsolete
else
  echo -e "${YELLOW}[!] mantendo pacotes antigos (--keep-old)${RESET}"
fi

# 4) migrate user.conf defaults if still pointing to foot/yazi
USER_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/user.conf"
if [[ -f "$USER_CONF" ]]; then
  sed -i \
    -e 's|TERMINAL_CMD=.*foot.*|TERMINAL_CMD="alacritty"|' \
    -e 's|TERMINAL_CLASS=.*foot.*|TERMINAL_CLASS="Alacritty"|' \
    -e 's|FILE_MANAGER_CMD=.*yazi.*|FILE_MANAGER_CMD="thunar"|' \
    "$USER_CONF" || true
  echo -e "${GREEN}[v]${RESET} user.conf ajustado (se tinha foot/yazi)"
fi

# 5) apply + session
"$DOTFILES/apply.sh"
"$DOTFILES/hooks/setup-session.sh"

# 6) portals hint for niri
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal"
if [[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal/niri-portals.conf" ]]; then
  cat > "${XDG_CONFIG_HOME:-$HOME/.config}/xdg-desktop-portal/niri-portals.conf" <<'EOF'
[preferred]
default=gnome;gtk;
EOF
fi

"$DOTFILES/doctor.sh" || true

echo
echo -e "${GREEN}=== Migração concluída ===${RESET}"
echo "1. Reinicie (ou faça logout)"
echo "2. No Ly, selecione: Niri (DMS)"
echo "3. Não use mais Hyprland (DMS)"
echo
echo "Update futuro: ~/dotfiles/update.sh"
