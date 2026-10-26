#!/usr/bin/env bash
# Menu unificado estilo Omarchy (Setup / Update / Sessão) — Super+Alt+Space
set -euo pipefail

SCRIPTS="${HOME}/.config/scripts"
PICKER="${SCRIPTS}/picker.sh"
DOTFILES="${HOME}/dotfiles"
TERM_RUN="${SCRIPTS}/run-in-term.sh"

toast() {
  local msg="$1"
  if command -v dms >/dev/null 2>&1; then
    dms ipc call toast info "$msg" >/dev/null 2>&1 || notify-send "Barista" "$msg"
  else
    notify-send "Barista" "$msg"
  fi
}

# Roda comando num Alacritty SEM tmux (um único string de comando)
run_term() {
  local title="$1"; shift
  BARISTA_TERM_TITLE="$title" "$TERM_RUN" "$*" &
  disown || true
}

main_menu() {
  local choice
  choice=$(printf '%s\n' \
    "⚙️  Setup" \
    "🔄 Update" \
    "🪟 Layouts" \
    "🔤 Escala de texto" \
    "🔌 Serviços (WARP / Dropbox / Docker)" \
    "🎛️  Unificar tema (GTK/Qt/Flatpak)" \
    "📎 Apps padrão (arquivos)" \
    "🎨 Tema de ícones" \
    "👆 Cadastrar digital" \
    "🔐 VPN / WARP" \
    "🤖 Coding agent" \
    "⏰ Lembretes" \
    "💻 Clamshell / Displays" \
    "🩺 Doctor" \
    "⌨️  Keybinds DMS" \
    "🛠️  Settings DMS" \
    | "$PICKER" -p "Barista")
  case "$choice" in
    "⚙️  Setup") setup_menu ;;
    "🔄 Update") update_menu ;;
    "🪟 Layouts") layouts_menu ;;
    "🔤 Escala de texto") "${SCRIPTS}/text-scale.sh" ;;
    "🔌 Serviços (WARP / Dropbox / Docker)") "${SCRIPTS}/service-toggle.sh" ;;
    "🎛️  Unificar tema (GTK/Qt/Flatpak)") "${SCRIPTS}/unify-desktop-theme.sh" ;;
    "📎 Apps padrão (arquivos)") "${SCRIPTS}/default-apps-menu.sh" ;;
    "🎨 Tema de ícones") "${SCRIPTS}/icon-theme-menu.sh" ;;
    "👆 Cadastrar digital") run_term "Fingerprint" "${SCRIPTS}/fingerprint-enroll.sh" ;;
    "🔐 VPN / WARP") vpn_menu ;;
    "🤖 Coding agent") "${SCRIPTS}/agent-launch.sh" ;;
    "⏰ Lembretes") "${SCRIPTS}/reminders.sh" ;;
    "💻 Clamshell / Displays") clamshell_menu ;;
    "🩺 Doctor") run_term "Doctor" "$DOTFILES/doctor.sh" ;;
    "⌨️  Keybinds DMS") dms ipc call keybinds toggle niri ;;
    "🛠️  Settings DMS") dms ipc call settings toggle ;;
  esac
}

setup_menu() {
  local choice
  choice=$(printf '%s\n' \
    "DNS → Cloudflare" \
    "DNS → DHCP (reset)" \
    "Aplicar dotfiles (apply.sh)" \
    "Migrar/atualizar stack" \
    "Sincronizar tema Alacritty" \
    "Sincronizar ícones tray" \
    "Sincronizar bordas niri (DMS)" \
    "Voltar" \
    | "$PICKER" -p "Setup")
  case "$choice" in
    "DNS → Cloudflare")
      nmcli networking connectivity >/dev/null 2>&1 || true
      # Define DNS Cloudflare nas conexões ativas ethernet/wifi
      while read -r uuid; do
        [[ -z "$uuid" ]] && continue
        nmcli connection modify "$uuid" ipv4.dns "1.1.1.1 1.0.0.1" ipv4.ignore-auto-dns yes 2>/dev/null || true
        nmcli connection up "$uuid" >/dev/null 2>&1 || true
      done < <(nmcli -t -f UUID,TYPE,DEVICE connection show --active | awk -F: '$2 ~ /ethernet|wifi|802-11/ {print $1}')
      toast "DNS → Cloudflare (1.1.1.1)"
      ;;
    "DNS → DHCP (reset)")
      while read -r uuid; do
        [[ -z "$uuid" ]] && continue
        nmcli connection modify "$uuid" ipv4.dns "" ipv4.ignore-auto-dns no 2>/dev/null || true
        nmcli connection up "$uuid" >/dev/null 2>&1 || true
      done < <(nmcli -t -f UUID,TYPE connection show --active | awk -F: '$2 ~ /ethernet|wifi|802-11/ {print $1}')
      toast "DNS → DHCP automático"
      ;;
    "Aplicar dotfiles (apply.sh)")
      toast "Rodando apply.sh…"
      ~/dotfiles/apply.sh && toast "apply OK" || toast "apply falhou"
      ;;
    "Migrar/atualizar stack")
      run_term "Update" "$DOTFILES/update.sh"
      ;;
    "Sincronizar tema Alacritty")
      ~/.config/scripts/sync-alacritty-theme-dms.sh && toast "Alacritty sync OK" || toast "sync falhou"
      ;;
    "Sincronizar ícones tray")
      ~/dotfiles/hooks/sync-tray-icons.sh && toast "Ícones tray OK" || toast "falhou"
      ;;
    "Sincronizar bordas niri (DMS)")
      "${SCRIPTS}/sync-niri-colors.sh" && toast "Bordas niri sync OK" || toast "sync falhou"
      ;;
    "Voltar") main_menu ;;
  esac
}

update_menu() {
  local choice
  choice=$(printf '%s\n' \
    "update.sh (dotfiles + pacotes)" \
    "yay -Syu (sistema)" \
    "dms / plugins reload" \
    "Voltar" \
    | "$PICKER" -p "Update")
  case "$choice" in
    "update.sh (dotfiles + pacotes)")
      run_term "Update dotfiles" "$DOTFILES/update.sh"
      ;;
    "yay -Syu (sistema)")
      run_term "yay -Syu" "yay -Syu"
      ;;
    "dms / plugins reload")
      dms ipc call plugins reload >/dev/null 2>&1 || true
      toast "plugins reload"
      ;;
    "Voltar") main_menu ;;
  esac
}

layouts_menu() {
  local choice
  choice=$(printf '%s\n' \
    "💾 Salvar layout atual" \
    "📂 Restaurar layout" \
    "🗑️  Apagar um layout" \
    "Voltar" \
    | "$PICKER" -p "Layouts")
  case "$choice" in
    "💾 Salvar layout atual") "${SCRIPTS}/layout-save.sh" ;;
    "📂 Restaurar layout") "${SCRIPTS}/layout-restore.sh" ;;
    "🗑️  Apagar um layout") "${SCRIPTS}/layout-restore.sh" --delete ;;
    "Voltar") main_menu ;;
  esac
}

vpn_menu() {
  local choice
  choice=$(printf '%s\n' \
    "NM VPN / WireGuard…" \
    "WARP status / toggle" \
    "Voltar" \
    | "$PICKER" -p "VPN")
  case "$choice" in
    "NM VPN / WireGuard…") "${SCRIPTS}/menu_vpn.sh" ;;
    "WARP status / toggle") "${SCRIPTS}/warp-toggle.sh" ;;
    "Voltar") main_menu ;;
  esac
}

clamshell_menu() {
  local choice
  choice=$(printf '%s\n' \
    "Clamshell ON (fecha lid → só externo)" \
    "Clamshell OFF (sempre lock no lid)" \
    "Forçar: desligar eDP agora" \
    "Forçar: ligar eDP agora" \
    "DMS Displays" \
    "Voltar" \
    | "$PICKER" -p "Clamshell")
  case "$choice" in
    "Clamshell ON (fecha lid → só externo)")
      mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/barista"
      echo on > "${XDG_STATE_HOME:-$HOME/.local/state}/barista/clamshell"
      toast "Clamshell ON"
      ;;
    "Clamshell OFF (sempre lock no lid)")
      mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/barista"
      echo off > "${XDG_STATE_HOME:-$HOME/.local/state}/barista/clamshell"
      toast "Clamshell OFF"
      ;;
    "Forçar: desligar eDP agora") "${SCRIPTS}/clamshell.sh" force-off-edp ;;
    "Forçar: ligar eDP agora") "${SCRIPTS}/clamshell.sh" force-on-edp ;;
    "DMS Displays") dms ipc call settings openWith displays >/dev/null 2>&1 || dms ipc call settings toggle ;;
    "Voltar") main_menu ;;
  esac
}

main_menu
