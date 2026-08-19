#!/usr/bin/env bash
# Conecta ao servidor RDP via FreeRDP (Hyprland/Wayland). NÃO use sudo.

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/rdp-server.conf"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/rdp-server.log"

log() {
    mkdir -p "$(dirname "$LOG")"
    printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"
}

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send "RDP" "$1" >/dev/null 2>&1 || true
}

if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Não use sudo. Roda: ~/.config/hypr/scripts/rdp-server.sh ou Super+R"
    exit 1
fi

if [[ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
    echo "Sem sessão gráfica. Use Super+R no Hyprland."
    exit 1
fi

if command -v xfreerdp3 >/dev/null 2>&1; then
    RDP_BIN=xfreerdp3
elif command -v sdl-freerdp3 >/dev/null 2>&1; then
    RDP_BIN=sdl-freerdp3
else
    notify "Instale freerdp: sudo pacman -S freerdp"
    exit 1
fi

# shellcheck source=/dev/null
[[ -f "$CONF" ]] && source "$CONF"

: "${RDP_HOST:=10.1.10.254}"
: "${RDP_PORT:=9299}"
: "${RDP_USER:=}"
: "${RDP_PASS:=}"
: "${RDP_AUTO_LOGIN:=1}"
: "${RDP_LOGIN_STYLE:=local}"

TARGET="${RDP_HOST}:${RDP_PORT}"

case "$RDP_LOGIN_STYLE" in
    local)   RDP_LOGIN=".\\${RDP_USER}" ;;
    plain)   RDP_LOGIN="${RDP_USER}" ;;
    *)       RDP_LOGIN="${RDP_LOGIN_STYLE}" ;;
esac

echo "RDP → ${TARGET}  ${RDP_LOGIN}"
notify "Conectando em ${TARGET}…"
log "target=${TARGET} login=${RDP_LOGIN} bin=${RDP_BIN}"

# Array bash: senha com ( ) * vai intacta, sem glob do shell
CMD=(
    "$RDP_BIN"
    "/v:${TARGET}"
    "/u:${RDP_LOGIN}"
    /sec:tls
    /cert:ignore
    /dynamic-resolution
    +clipboard
    /network:auto
    /compression-level:2
)

if [[ "$RDP_AUTO_LOGIN" == "1" && -n "$RDP_PASS" ]]; then
    CMD+=("/p:${RDP_PASS}")
fi

log "exec ${CMD[*]//\/p:*/\/p:***}"
exec "${CMD[@]}"
