#!/usr/bin/env bash
# Wizard de impressoras (CUPS) — mesmo padrão dos menus Hyprland (fuzzel + zenity).
set -euo pipefail

PICKER="${HOME}/.config/hypr/scripts/picker.sh"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/hypr/printer-wizard.log"
# PDF real — o banner "testprint" do CUPS costuma gerar 0 páginas em IPP Everywhere (Brother etc.)
TESTPRINT="/usr/share/cups/data/default-testpage.pdf"

log() {
    mkdir -p "$(dirname "$LOG")"
    printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG"
}

notify() {
    local urgency="${2:-normal}"
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send -u "$urgency" "Impressora" "$1" >/dev/null 2>&1 || true
}

pick() {
    local prompt="$1"
    "$PICKER" -p "$prompt" || true
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1
}

ensure_cups() {
    if ! need_cmd lpstat || ! need_cmd lpadmin || ! need_cmd lpinfo; then
        notify "CUPS não encontrado. Instale: sudo pacman -S cups cups-pk-helper" critical
        exit 1
    fi

    # Avahi melhora descoberta driverless (ippfind); sem ele a impressão por IP ainda funciona
    if need_cmd systemctl && ! systemctl is-active --quiet avahi-daemon 2>/dev/null; then
        if systemctl list-unit-files avahi-daemon.service >/dev/null 2>&1; then
            pkexec systemctl enable --now avahi-daemon >/dev/null 2>&1 || true
            log "tentativa de iniciar avahi-daemon"
        fi
    fi

    if lpstat -r 2>/dev/null | grep -Eiq 'running|execução'; then
        return 0
    fi

    if ! need_cmd zenity; then
        notify "Serviço CUPS parado. Ative com: sudo systemctl enable --now cups" critical
        exit 1
    fi

    if zenity --question \
        --title="Impressora" \
        --text="O serviço de impressão (CUPS) não está ativo.\n\nDeseja iniciar agora?" \
        --ok-label="Iniciar" \
        --cancel-label="Cancelar" 2>/dev/null; then
        if pkexec systemctl enable --now cups; then
            notify "CUPS iniciado."
            log "cups enabled/started via pkexec"
        else
            notify "Não foi possível iniciar o CUPS." critical
            exit 1
        fi
    else
        exit 0
    fi
}

run_lpadmin() {
    # Tenta como usuário (cups-pk-helper / grupo); se falhar, pkexec
    mkdir -p "$(dirname "$LOG")"
    if lpadmin "$@" 2>>"$LOG"; then
        return 0
    fi
    log "lpadmin falhou como usuário; tentando pkexec ($*)"
    if pkexec lpadmin "$@" 2>>"$LOG"; then
        return 0
    fi
    return 1
}

sanitize_name() {
    # Nome CUPS: letras, números, hífen, underscore
    echo "$1" | tr -cd 'A-Za-z0-9._-' | cut -c1-40
}

# Extrai host de uris tipo socket://IP:9100, ipp://IP/ipp/print, etc.
uri_host() {
    local uri="$1"
    uri="${uri#*://}"
    uri="${uri%%/*}"
    uri="${uri%%:*}"
    printf '%s' "$uri"
}

# Testa se um endpoint IPP responde (timeout curto)
ipp_alive() {
    local uri="$1"
    need_cmd ipptool || return 1
    timeout 3 ipptool -t "$uri" get-printer-attributes.test >/dev/null 2>&1
}

# Dado um host, escolhe o melhor URI IPP e devolve make-and-model via stdout:
#   IPP_URI<TAB>MAKE_MODEL
# ou vazio se IPP indisponível.
ipp_probe_host() {
    local host="$1"
    local candidate attrs make

    need_cmd ipptool || return 1

    for candidate in \
        "ipp://${host}/ipp/print" \
        "ipp://${host}:631/ipp/print" \
        "ipp://${host}/ipp/printer" \
        "ipp://${host}:631/ipp/printer"; do
        attrs="$(timeout 4 ipptool -tv "$candidate" get-printer-attributes.test 2>/dev/null || true)"
        [[ -z "$attrs" ]] && continue
        make="$(printf '%s\n' "$attrs" | sed -n 's/.*printer-make-and-model (textWithoutLanguage) = //p' | head -1)"
        [[ -z "$make" ]] && make="$(printf '%s\n' "$attrs" | sed -n 's/.*printer-info (textWithoutLanguage) = //p' | head -1)"
        [[ -z "$make" ]] && make="Impressora ${host}"

        # Preferir everywhere quando a impressora fala URF / PWG-raster / PDF
        if printf '%s\n' "$attrs" | grep -Eqi 'image/urf|image/pwg-raster|application/pdf'; then
            printf '%s\t%s\teverywhere\n' "$candidate" "$make"
            return 0
        fi

        printf '%s\t%s\t\n' "$candidate" "$make"
        return 0
    done
    return 1
}

# Procura em lpinfo -m um PPD que case com o modelo (ex.: "Samsung SCX-3400 Series")
match_ppd_for_model() {
    local make_model="$1"
    local tokens token hits best

    [[ -z "$make_model" ]] && return 1

    # Tokens úteis: marca + códigos tipo SCX-3400
    tokens="$(printf '%s\n' "$make_model" \
        | tr '[:upper:]' '[:lower:]' \
        | tr -cs 'a-z0-9.-' ' ' \
        | awk '{for(i=1;i<=NF;i++) if(length($i)>=3 && $i !~ /^(the|and|series|printer|laser)$/) print $i}')"

    hits="$(lpinfo -m 2>/dev/null || true)"
    [[ -z "$hits" ]] && return 1

    # 1) match "marca + modelo" (todos os tokens significativos)
    best="$hits"
    while IFS= read -r token; do
        [[ -z "$token" ]] && continue
        best="$(printf '%s\n' "$best" | grep -iF -- "$token" || true)"
        [[ -z "$best" ]] && break
    done <<<"$tokens"

    if [[ -n "$best" ]]; then
        # Preferir linha "Simplified"/everywhere-like se houver várias
        printf '%s\n' "$best" | head -1 | awk '{print $1}'
        return 0
    fi

    # 2) só a marca (primeiro token)
    token="$(printf '%s\n' "$tokens" | head -1)"
    if [[ -n "$token" ]]; then
        best="$(printf '%s\n' "$hits" | grep -iF -- "$token" | head -1 || true)"
        if [[ -n "$best" ]]; then
            printf '%s\n' "$best" | awk '{print $1}'
            return 0
        fi
    fi

    return 1
}

# Decide driver recomendado: id CUPS (+ label humana em RECOMMENDED_LABEL)
recommend_driver() {
    local make_model="$1"
    local prefer_everywhere="$2" # 1/0
    local ppd

    # URF / PWG-raster / PDF → IPP Everywhere é o melhor caminho moderno
    if [[ "$prefer_everywhere" == "1" ]]; then
        RECOMMENDED_DRIVER="everywhere"
        RECOMMENDED_LABEL="IPP Everywhere (recomendado para ${make_model})"
        return 0
    fi

    # Sem raster moderno: tenta PPD instalado pelo modelo
    if ppd="$(match_ppd_for_model "$make_model")"; then
        RECOMMENDED_DRIVER="$ppd"
        RECOMMENDED_LABEL="PPD correspondente: ${ppd}"
        return 0
    fi

    # Último recurso em rede IPP: still everywhere (muitas Samsung/HP antigas aceitam)
    RECOMMENDED_DRIVER="everywhere"
    RECOMMENDED_LABEL="IPP Everywhere (fallback para ${make_model})"
    return 0
}

# Se URI for socket/IPP com host, tenta IPP + driver recomendado.
# Define: RESOLVED_URI, DETECTED_MODEL, RECOMMENDED_DRIVER, RECOMMENDED_LABEL
resolve_network_printer() {
    local uri="$1"
    local host probe ipp_uri make prefer_everywhere

    RESOLVED_URI="$uri"
    DETECTED_MODEL=""
    RECOMMENDED_DRIVER=""
    RECOMMENDED_LABEL=""

    host="$(uri_host "$uri")"
    [[ -z "$host" ]] && return 1

    # socket://IP sem porta de path — ou já ipp://
    if [[ "$uri" == socket://* || "$uri" == ipp://* || "$uri" == ipps://* ]]; then
        notify "Consultando impressora em ${host}…"
        if probe="$(ipp_probe_host "$host")"; then
            ipp_uri="$(printf '%s\n' "$probe" | cut -f1)"
            make="$(printf '%s\n' "$probe" | cut -f2)"
            prefer_everywhere="$(printf '%s\n' "$probe" | cut -f3)"
            [[ "$prefer_everywhere" == "everywhere" ]] && prefer_everywhere=1 || prefer_everywhere=0

            RESOLVED_URI="$ipp_uri"
            DETECTED_MODEL="$make"
            log "ipp probe host=${host} uri=${ipp_uri} model=${make} everywhere=${prefer_everywhere}"

            if recommend_driver "$make" "$prefer_everywhere"; then
                log "recommended driver=${RECOMMENDED_DRIVER}"
                return 0
            fi
            return 0
        fi
        log "ipp probe falhou para host=${host}; mantendo uri=${uri}"
    fi
    return 1
}

list_devices() {
    local filter="$1" # usb | network | all
    # lpinfo -v: "<class> <uri> [descrição opcional]"
    lpinfo -v 2>/dev/null | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local class uri desc
        class="${line%% *}"
        uri="${line#"$class" }"
        uri="${uri%% *}"
        desc="${line#"$class" }"
        desc="${desc#"$uri"}"
        desc="${desc# }"
        [[ -z "$desc" ]] && desc="$uri"

        case "$filter" in
            usb)
                [[ "$uri" == usb://* ]] || continue
                ;;
            network)
                [[ "$uri" == dnssd://* || "$uri" == ipp://* || "$uri" == ipps://* || "$uri" == socket://* || "$uri" == lpd://* ]] || continue
                ;;
        esac

        # Ignora backends genéricos sem dispositivo concreto
        case "$uri" in
            usb | parallel | serial | beh | http | https | ipp | ipps | lpd | socket | dnssd | smb | cups-pdf:/)
                continue
                ;;
        esac

        printf '%s\t%s\n' "$uri" "$desc"
    done
}

pick_device() {
    local filter="$1"
    local prompt="$2"
    local lines labels uri desc chosen

    lines="$(list_devices "$filter")"
    if [[ -z "$lines" ]]; then
        notify "Nenhuma impressora encontrada ($filter). Verifique cabo/rede."
        return 1
    fi

    labels=""
    declare -A URI_MAP=()
    while IFS=$'\t' read -r uri desc; do
        [[ -z "$uri" ]] && continue
        local label
        label="${desc}  (${uri})"
        URI_MAP["$label"]="$uri"
        labels+="$label"$'\n'
    done <<<"$lines"

    chosen="$(printf '%s' "$labels" | sed '/^$/d' | pick "$prompt")"
    [[ -z "$chosen" ]] && return 1
    printf '%s' "${URI_MAP[$chosen]}"
}

ask_name() {
    local suggestion="$1"
    if need_cmd zenity; then
        zenity --entry \
            --title="Nome da impressora" \
            --text="Como deseja chamar esta impressora?" \
            --entry-text="$suggestion" 2>/dev/null || true
    else
        printf '%s' "$suggestion"
    fi
}

add_printer_uri() {
    local uri="$1"
    local suggestion name model driver_label

    RESOLVED_URI="$uri"
    DETECTED_MODEL=""
    RECOMMENDED_DRIVER=""
    RECOMMENDED_LABEL=""

    # Rede/IP: sobe para IPP quando possível e escolhe driver recomendado
    if [[ "$uri" == socket://* || "$uri" == ipp://* || "$uri" == ipps://* || "$uri" == dnssd://* ]]; then
        # dnssd: tenta extrair host .local se houver; senão segue URI original
        if [[ "$uri" == dnssd://* ]]; then
            RESOLVED_URI="$uri"
            # dnssd já costuma ser IPP; tenta everywhere direto
            RECOMMENDED_DRIVER="everywhere"
            RECOMMENDED_LABEL="IPP Everywhere (descoberta na rede)"
            DETECTED_MODEL="$(printf '%s' "$uri" | sed 's|dnssd://||; s|\._ipp\._tcp.*||; s|%20| |g')"
        else
            resolve_network_printer "$uri" || true
        fi
    fi

    uri="${RESOLVED_URI:-$uri}"

    if [[ -n "${DETECTED_MODEL:-}" ]]; then
        suggestion="$(sanitize_name "$DETECTED_MODEL")"
    else
        suggestion="$(sanitize_name "${uri##*/}")"
        suggestion="${suggestion%%\?*}"
    fi
    [[ -z "$suggestion" ]] && suggestion="Impressora"

    name="$(ask_name "$suggestion")"
    [[ -z "$name" ]] && return 0
    name="$(sanitize_name "$name")"
    [[ -z "$name" ]] && {
        notify "Nome inválido." critical
        return 1
    }

    notify "Adicionando ${name}…"
    log "add name=${name} uri=${uri} recommended=${RECOMMENDED_DRIVER:-none} model=${DETECTED_MODEL:-}"

    # 1) Driver recomendado (auto)
    if [[ -n "${RECOMMENDED_DRIVER:-}" ]]; then
        if run_lpadmin -p "$name" -v "$uri" -m "$RECOMMENDED_DRIVER" -E \
            -o printer-error-policy=retry-job 2>>"$LOG"; then
            driver_label="${RECOMMENDED_LABEL:-$RECOMMENDED_DRIVER}"
            notify "Impressora ${name} adicionada.\n${driver_label}"
            offer_test "$name"
            return 0
        fi
        log "driver recomendado falhou: ${RECOMMENDED_DRIVER}"
    fi

    # 2) Fallback IPP Everywhere
    if [[ "${RECOMMENDED_DRIVER:-}" != "everywhere" ]]; then
        if run_lpadmin -p "$name" -v "$uri" -m everywhere -E \
            -o printer-error-policy=retry-job 2>>"$LOG"; then
            notify "Impressora ${name} adicionada (IPP Everywhere)."
            offer_test "$name"
            return 0
        fi
    fi

    log "auto driver falhou; pedindo driver em lpinfo -m"

    # 3) Escolher driver instalado manualmente
    model="$(lpinfo -m 2>/dev/null | pick "Driver / PPD" | awk '{print $1}')"
    if [[ -z "$model" ]]; then
        notify "Adição cancelada ou sem driver." critical
        return 1
    fi

    if run_lpadmin -p "$name" -v "$uri" -m "$model" -E \
        -o printer-error-policy=retry-job 2>>"$LOG"; then
        notify "Impressora ${name} adicionada."
        offer_test "$name"
        return 0
    fi

    notify "Falha ao adicionar ${name}. Veja ${LOG}" critical
    return 1
}

add_manual_ip() {
    local host uri
    if ! need_cmd zenity; then
        notify "zenity é necessário para IP manual." critical
        return 1
    fi

    host="$(zenity --entry --title="Impressora na rede" --text="IP ou hostname da impressora:" 2>/dev/null || true)"
    [[ -z "$host" ]] && return 0
    # remove protocolo/porta se o usuário colar URI completa
    host="${host#*://}"
    host="${host%%/*}"
    host="${host%%:*}"

    # Preferir IPP; resolve_network_printer faz o probe e escolhe o driver
    uri="ipp://${host}/ipp/print"
    if ! ipp_alive "$uri"; then
        uri="socket://${host}:9100"
    fi

    add_printer_uri "$uri"
}

offer_test() {
    local name="$1"
    if need_cmd zenity && zenity --question \
        --title="Página de teste" \
        --text="Enviar página de teste para ${name}?" \
        --ok-label="Enviar" \
        --cancel-label="Agora não" 2>/dev/null; then
        send_test "$name"
    fi
}

send_test() {
    local name="$1"
    local out job_id i state pages

    if [[ ! -f "$TESTPRINT" ]]; then
        notify "Arquivo de teste CUPS não encontrado." critical
        return 1
    fi

    # Garante que a fila aceita jobs (job anterior com ErrorPolicy stop-printer trava)
    cupsenable "$name" >/dev/null 2>&1 || true
    cupsaccept "$name" >/dev/null 2>&1 || true

    notify "Enviando página de teste para ${name}…"
    if ! out="$(lp -d "$name" -t "teste-barista" "$TESTPRINT" 2>&1)"; then
        notify "Falha ao enviar página de teste." critical
        log "testprint submit fail name=${name} out=${out}"
        return 1
    fi
    log "testprint submit name=${name} out=${out}"

    job_id="$(printf '%s\n' "$out" | grep -oE '[0-9]+' | tail -1)"
    [[ -z "$job_id" ]] && job_id="?"

    # Espera o job sair da fila / impressora voltar à idle (até ~45s)
    for i in $(seq 1 45); do
        sleep 1
        state="$(lpstat -p "$name" 2>/dev/null || true)"
        if ! lpstat -o "$name" 2>/dev/null | grep -q "${name}-${job_id}"; then
            # Job saiu da fila ativa — confere page_log
            pages="$(awk -v p="$name" -v j="$job_id" '
                $1 == p && $3 == j {
                    for (i = 1; i <= NF; i++)
                        if ($i == "total") { print $(i + 1); exit }
                }
            ' /var/log/cups/page_log 2>/dev/null || true)"
            if [[ -n "$pages" && "$pages" -gt 0 ]]; then
                notify "Teste OK: ${pages} página(s) impressa(s) em ${name}."
                log "testprint ok name=${name} job=${job_id} pages=${pages}"
                return 0
            fi
            # Sem page_log legível, mas fila livre e impressora idle = provavelmente OK
            if printf '%s\n' "$state" | grep -Eiq 'inativa|idle|pronta|ready'; then
                notify "Teste enviado a ${name} (job ${job_id}). Confira a bandeja."
                log "testprint done-sem-pages name=${name} job=${job_id}"
                return 0
            fi
            break
        fi
        if printf '%s\n' "$state" | grep -Eiq 'desabilitada|disabled|parado|stopped|error'; then
            notify "Impressora ${name} parou com erro no teste. Veja ${LOG}" critical
            log "testprint printer-stopped name=${name} job=${job_id} state=${state}"
            return 1
        fi
    done

    notify "Teste demorou demais ou não confirmou páginas. Job ${job_id} — veja a Brother." critical
    log "testprint timeout name=${name} job=${job_id}"
    return 1
}

installed_printers() {
    lpstat -a 2>/dev/null | awk '{print $1}' || true
}

pick_installed() {
    local prompt="$1"
    local list
    list="$(installed_printers)"
    if [[ -z "$list" ]]; then
        notify "Nenhuma impressora instalada."
        return 1
    fi
    printf '%s\n' "$list" | pick "$prompt"
}

menu_manage() {
    local name action
    name="$(pick_installed "Impressoras instaladas")" || return 0
    [[ -z "$name" ]] && return 0

    action="$(printf '%s\n' \
        "Página de teste" \
        "Definir como padrão" \
        "Remover" \
        | pick "${name}")"
    [[ -z "$action" ]] && return 0

    case "$action" in
        "Página de teste")
            send_test "$name"
            ;;
        "Definir como padrão")
            if lpoptions -d "$name" >>"$LOG" 2>&1; then
                notify "${name} definida como padrão."
            else
                notify "Não foi possível definir padrão." critical
            fi
            ;;
        "Remover")
            if need_cmd zenity && ! zenity --question \
                --title="Remover impressora" \
                --text="Remover ${name}?" \
                --ok-label="Remover" \
                --cancel-label="Cancelar" 2>/dev/null; then
                return 0
            fi
            if run_lpadmin -x "$name" 2>>"$LOG"; then
                notify "${name} removida."
            else
                notify "Falha ao remover ${name}." critical
            fi
            ;;
    esac
}

menu_add() {
    local choice uri
    choice="$(printf '%s\n' \
        "USB (plugada neste PC)" \
        "Rede (descoberta automática)" \
        "IP / hostname manual" \
        | pick "Adicionar impressora")"
    [[ -z "$choice" ]] && return 0

    case "$choice" in
        "USB"*)
            notify "Procurando impressoras USB…"
            uri="$(pick_device usb "Impressoras USB")" || return 0
            [[ -z "$uri" ]] && return 0
            add_printer_uri "$uri"
            ;;
        "Rede"*)
            notify "Procurando impressoras na rede…"
            uri="$(pick_device network "Impressoras na rede")" || return 0
            [[ -z "$uri" ]] && return 0
            add_printer_uri "$uri"
            ;;
        "IP"*)
            add_manual_ip
            ;;
    esac
}

menu_test() {
    local name
    name="$(pick_installed "Página de teste")" || return 0
    [[ -z "$name" ]] && return 0
    send_test "$name"
}

menu_remove() {
    local name
    name="$(pick_installed "Remover impressora")" || return 0
    [[ -z "$name" ]] && return 0
    if need_cmd zenity && ! zenity --question \
        --title="Remover impressora" \
        --text="Remover ${name}?" \
        --ok-label="Remover" \
        --cancel-label="Cancelar" 2>/dev/null; then
        return 0
    fi
    if run_lpadmin -x "$name" 2>>"$LOG"; then
        notify "${name} removida."
    else
        notify "Falha ao remover ${name}." critical
    fi
}

main() {
    ensure_cups

    local choice
    choice="$(printf '%s\n' \
        "Adicionar impressora" \
        "Impressoras instaladas" \
        "Página de teste" \
        "Remover impressora" \
        | pick "Impressoras")"
    [[ -z "$choice" ]] && exit 0

    case "$choice" in
        "Adicionar"*) menu_add ;;
        "Impressoras instaladas") menu_manage ;;
        "Página de teste") menu_test ;;
        "Remover"*) menu_remove ;;
    esac
}

main "$@"
