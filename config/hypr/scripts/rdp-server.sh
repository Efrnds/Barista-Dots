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
if [[ ! -f "$CONF" ]]; then
    mkdir -p "$(dirname "$CONF")"
    cat > "$CONF" << 'EOF'
# Configuração do Servidor RDP
# Usado pelo script Super+R (~/.config/hypr/scripts/rdp-server.sh)

RDP_HOST="10.1.10.254"
RDP_PORT="9299"
RDP_USER="eduardo"
RDP_PASS=""
RDP_AUTO_LOGIN=1
RDP_LOGIN_STYLE="local"  # 'local' (.\usuario), 'plain' (usuario) ou 'DOMINIO\usuario'
RDP_SEC="tls"            # 'tls', 'nla' ou 'rdp'
EOF
    chmod 600 "$CONF"
fi

[[ -f "$CONF" ]] && source "$CONF"

: "${RDP_HOST:=10.1.10.254}"
: "${RDP_PORT:=9299}"
: "${RDP_USER:=}"
: "${RDP_PASS:=}"
: "${RDP_AUTO_LOGIN:=1}"
: "${RDP_LOGIN_STYLE:=local}"
: "${RDP_SEC:=tls}"

TARGET="${RDP_HOST}:${RDP_PORT}"

# Se usuário ou senha não estiverem definidos e o auto-login estiver ativo, solicita via interface gráfica
if [[ -z "$RDP_USER" || ( "$RDP_AUTO_LOGIN" == "1" && -z "$RDP_PASS" ) ]]; then
    if command -v zenity >/dev/null 2>&1; then
        CREDENTIALS=$(zenity --password --username --title="Acesso RDP - ${TARGET}" 2>/dev/null)
        if [[ $? -ne 0 || -z "$CREDENTIALS" ]]; then
            notify "Conexão RDP cancelada."
            exit 0
        fi
        INPUT_USER="${CREDENTIALS%%|*}"
        INPUT_PASS="${CREDENTIALS#*|}"
        [[ -n "$INPUT_USER" ]] && RDP_USER="$INPUT_USER"
        [[ -n "$INPUT_PASS" ]] && RDP_PASS="$INPUT_PASS"
    fi
fi

if [[ -z "$RDP_USER" ]]; then
    notify "Erro: Usuário RDP não configurado. Edite $CONF"
    exit 1
fi

case "$RDP_LOGIN_STYLE" in
    local)   RDP_LOGIN=".\\${RDP_USER}" ;;
    plain)   RDP_LOGIN="${RDP_USER}" ;;
    *)       RDP_LOGIN="${RDP_LOGIN_STYLE}" ;;
esac

echo "RDP → ${TARGET}  ${RDP_LOGIN}"
notify "Conectando em ${TARGET} (${RDP_LOGIN})…"
log "target=${TARGET} login=${RDP_LOGIN} bin=${RDP_BIN}"

# Array bash: senha com ( ) * vai intacta, sem glob do shell
CMD=(
    "$RDP_BIN"
    "/v:${TARGET}"
    "/u:${RDP_LOGIN}"
    "/title:RDP - ${TARGET}"
    "/sec:${RDP_SEC}"
    /cert:ignore
    /dynamic-resolution
    +clipboard
    /network:auto
    /compression-level:2
)

if [[ -n "$RDP_PASS" ]]; then
    CMD+=("/p:${RDP_PASS}")
fi

log "exec ${CMD[*]//\/p:*/\/p:***}"
"${CMD[@]}" >>"$LOG" 2>&1
EXIT_CODE=$?

log "freerdp exit code: ${EXIT_CODE}"
if [[ ${EXIT_CODE} -ne 0 && ${EXIT_CODE} -ne 130 ]]; then
    notify "Falha na conexão RDP (código ${EXIT_CODE}). Verifique ${LOG}"
fi
exit ${EXIT_CODE}
