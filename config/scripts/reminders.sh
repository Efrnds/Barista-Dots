#!/usr/bin/env bash
# Lembretes simples via systemd-run --user (Super+Ctrl+R)
set -euo pipefail

PICKER="${HOME}/.config/scripts/picker.sh"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/barista/reminders"
mkdir -p "$STATE"

choice=$(printf '%s\n' \
  "➕ Novo lembrete" \
  "📋 Listar pendentes" \
  "❌ Cancelar um" \
  | "$PICKER" -p "Lembretes")

toast() { dms ipc call toast info "$1" >/dev/null 2>&1 || notify-send "Lembrete" "$1"; }

case "$choice" in
  "➕ Novo lembrete")
    when=$(printf '%s\n' "5m" "10m" "15m" "30m" "1h" "2h" "custom…" | "$PICKER" -p "Quando")
    [[ -z "${when:-}" ]] && exit 0
    if [[ "$when" == "custom…" ]]; then
      when=$(echo "20m" | "$PICKER" -p "ex: 45m / 2h / 1d" || true)
      [[ -z "${when:-}" ]] && exit 0
    fi
    msg=$(echo "Beber água" | "$PICKER" -p "Mensagem" || true)
    [[ -z "${msg:-}" ]] && msg="Lembrete"
    # systemd-run on-active
    unit="barista-reminder-$(date +%s)"
    systemd-run --user --on-active="$when" --timer-property=AccuracySec=1s \
      --unit="$unit" \
      /usr/bin/bash -lc "notify-send -u critical '⏰ Lembrete' $(printf %q "$msg"); dms ipc call toast warn $(printf %q "$msg") >/dev/null 2>&1 || true" \
      >/dev/null
    echo "$unit|$when|$msg|$(date -Iseconds)" >>"$STATE/log.txt"
    toast "Em ${when}: ${msg}"
    ;;
  "📋 Listar pendentes")
    list=$(systemctl --user list-timers --all 2>/dev/null | rg -i 'barista-reminder' || true)
    if [[ -z "$list" ]]; then
      toast "Nenhum lembrete pendente"
    else
      echo "$list" | "$PICKER" -p "Pendentes" >/dev/null || true
    fi
    ;;
  "❌ Cancelar um")
    mapfile -t units < <(systemctl --user list-timers --all --no-legend 2>/dev/null | awk '{print $NF}' | rg 'barista-reminder' || true)
    if [[ ${#units[@]} -eq 0 ]]; then
      toast "Nada para cancelar"
      exit 0
    fi
    u=$(printf '%s\n' "${units[@]}" | "$PICKER" -p "Cancelar")
    [[ -z "${u:-}" ]] && exit 0
    systemctl --user stop "$u" 2>/dev/null || true
    systemctl --user stop "${u%.timer}.service" 2>/dev/null || true
    toast "Cancelado: $u"
    ;;
esac
