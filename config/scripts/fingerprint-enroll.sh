#!/usr/bin/env bash
# Cadastra digitais (várias, como no celular).
set -euo pipefail

SCRIPTS="${HOME}/.config/scripts"
PICKER="${SCRIPTS}/picker.sh"
USER_NAME="${USER}"

FINGERS=(
  "right-index-finger|Indicador direito"
  "right-thumb|Polegar direito"
  "right-middle-finger|Médio direito"
  "right-ring-finger|Anelar direito"
  "right-little-finger|Mindinho direito"
  "left-index-finger|Indicador esquerdo"
  "left-thumb|Polegar esquerdo"
  "left-middle-finger|Médio esquerdo"
  "left-ring-finger|Anelar esquerdo"
  "left-little-finger|Mindinho esquerdo"
)

enrolled() {
  fprintd-list "$USER_NAME" 2>/dev/null | rg -o '#[0-9]+: \K.*' || true
}

toast() {
  dms ipc call toast info "$1" >/dev/null 2>&1 || notify-send "Digital" "$1"
}

show_list() {
  local list
  list=$(enrolled)
  if [[ -z "$list" ]]; then
    echo "(nenhuma digital cadastrada)"
  else
    echo "$list"
  fi
}

do_enroll() {
  local finger="$1" label="$2"
  echo "=== Cadastrando: $label ($finger) ==="
  echo "Encoste/levante o dedo no leitor várias vezes quando pedido."
  if fprintd-enroll -f "$finger" "$USER_NAME"; then
    toast "Digital OK: $label"
  else
    toast "Falha ao cadastrar $label"
    return 1
  fi
}

do_delete() {
  local list choice finger
  mapfile -t list < <(enrolled)
  if [[ ${#list[@]} -eq 0 ]]; then
    toast "Nenhuma digital pra apagar"
    return
  fi
  choice=$(printf '%s\n' "${list[@]}" "Cancelar" | "$PICKER" -p "Apagar digital")
  [[ -z "${choice:-}" || "$choice" == Cancelar ]] && return
  finger="$choice"
  if fprintd-delete "$USER_NAME" "$finger" 2>/dev/null; then
    toast "Apagada: $finger"
  else
    # alguns clients só apagam todas
    echo "Não deu pra apagar só essa. Apagar TODAS as digitais de $USER_NAME?"
    conf=$(printf '%s\n' "Sim, apagar todas" "Cancelar" | "$PICKER" -p "Confirmar")
    if [[ "$conf" == "Sim, apagar todas" ]]; then
      fprintd-delete "$USER_NAME"
      toast "Todas as digitais apagadas"
    fi
  fi
}

main() {
  # se rodando em TTY sem picker (terminal puro), mode simples
  if [[ ! -t 0 ]] || [[ "${1:-}" == "--finger" ]]; then
    local f="${2:-right-index-finger}"
    exec fprintd-enroll -f "$f" "$USER_NAME"
  fi

  while true; do
    local cur choice label finger entry
    cur=$(show_list | tr '\n' ', ' | sed 's/, $//')
    choice=$(printf '%s\n' \
      "Cadastrar outra digital…" \
      "Ver cadastradas" \
      "Apagar digital…" \
      "Sair" \
      | "$PICKER" -p "Digitais (${cur:-nenhuma})")
    case "$choice" in
      "Cadastrar outra digital…")
        choice=$(printf '%s\n' "${FINGERS[@]#*|}" "Cancelar" | "$PICKER" -p "Qual dedo?")
        [[ -z "${choice:-}" || "$choice" == Cancelar ]] && continue
        for entry in "${FINGERS[@]}"; do
          finger="${entry%%|*}"
          label="${entry#*|}"
          if [[ "$label" == "$choice" ]]; then
            # roda enroll no terminal visível
            if [[ -t 1 ]]; then
              do_enroll "$finger" "$label"
            else
              BARISTA_TERM_TITLE="Fingerprint" "${SCRIPTS}/run-in-term.sh" \
                "echo 'Cadastro: $label'; fprintd-enroll -f '$finger' '$USER_NAME'; echo; read -r -p 'Enter…'"
            fi
            break
          fi
        done
        ;;
      "Ver cadastradas")
        printf '%s\n' "$(show_list)" "OK" | "$PICKER" -p "Cadastradas" >/dev/null || true
        ;;
      "Apagar digital…") do_delete ;;
      "Sair"|"") exit 0 ;;
    esac
  done
}

main "$@"
