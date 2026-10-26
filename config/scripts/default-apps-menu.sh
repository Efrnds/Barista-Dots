#!/usr/bin/env bash
# Apps padrão — estilo "Default apps" do Windows (xdg-mime + mimeapps.list)
set -euo pipefail

SCRIPTS="${HOME}/.config/scripts"
PICKER="${SCRIPTS}/picker.sh"
MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"

toast() {
  local m="$1"
  dms ipc call toast info "$m" >/dev/null 2>&1 || notify-send "Apps padrão" "$m"
}

# Categorias: label|mime1,mime2,...
# (todos os MIMEs da linha recebem o mesmo .desktop)
CATEGORIES=(
  "Navegador (HTTP/HTML)|x-scheme-handler/http,x-scheme-handler/https,text/html"
  "Gerenciador de arquivos|inode/directory"
  "Imagens|image/png,image/jpeg,image/webp,image/gif,image/svg+xml,image/bmp"
  "Vídeo|video/mp4,video/x-matroska,video/webm,video/x-msvideo"
  "Áudio|audio/mpeg,audio/flac,audio/ogg,audio/x-wav,audio/mp4"
  "PDF|application/pdf"
  "Texto|text/plain"
  "Markdown|text/markdown"
  "Código (JS/TS/CSS/JSON)|application/javascript,text/javascript,text/css,application/json,text/x-python,text/x-typescript"
  "Office (docs)|application/vnd.openxmlformats-officedocument.wordprocessingml.document,application/msword,application/vnd.oasis.opendocument.text"
  "Office (planilha)|application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel,application/vnd.oasis.opendocument.spreadsheet"
  "Arquivos compactados|application/zip,application/x-7z-compressed,application/x-rar-compressed,application/gzip"
  "Terminal (scheme)|x-scheme-handler/terminal"
  "E-mail (mailto)|x-scheme-handler/mailto"
)

desktop_name() {
  local desk="$1" base name=""
  [[ -z "$desk" || "$desk" == "-" ]] && { echo "(nenhum)"; return; }
  for base in "$HOME/.local/share/applications" /usr/share/applications /var/lib/flatpak/exports/share/applications; do
    if [[ -f "$base/$desk" ]]; then
      name=$(rg -m1 '^Name=' "$base/$desk" 2>/dev/null | sed 's/^Name=//' || true)
      [[ -n "$name" ]] && { echo "$name"; return; }
    fi
  done
  echo "${desk%.desktop}"
}

current_default() {
  local mime="$1"
  xdg-mime query default "$mime" 2>/dev/null || true
}

# Lista apps que declaram o MIME (Name|desktop)
list_handlers() {
  local mime="$1"
  python3 - "$mime" <<'PY'
import os, sys
from pathlib import Path

mime = sys.argv[1]
seen = set()
bases = [
    Path.home() / ".local/share/applications",
    Path("/usr/share/applications"),
    Path("/var/lib/flatpak/exports/share/applications"),
]
for base in bases:
    if not base.is_dir():
        continue
    for f in sorted(base.glob("*.desktop")):
        try:
            text = f.read_text(errors="ignore")
        except Exception:
            continue
        if "MimeType=" not in text:
            continue
        # extract MimeType line(s)
        mimes = []
        for line in text.splitlines():
            if line.startswith("MimeType="):
                mimes.extend([m for m in line[9:].split(";") if m])
        if mime not in mimes:
            continue
        if f.name in seen:
            continue
        # skip hidden unless it's already default-capable
        nodisplay = any(l.strip() == "NoDisplay=true" for l in text.splitlines())
        if nodisplay:
            continue
        name = f.stem
        for line in text.splitlines():
            if line.startswith("Name=") and not line.startswith("Name["):
                name = line[5:]
                break
        seen.add(f.name)
        print(f"{name}\t{f.name}")
PY
}

set_defaults() {
  local desk="$1"
  shift
  local mime
  for mime in "$@"; do
    [[ -z "$mime" ]] && continue
    xdg-mime default "$desk" "$mime"
  done
  # ensure mimeapps.list has them (xdg-mime usually writes this)
  toast "Padrão → $(desktop_name "$desk")"
}

pick_app_for_mimes() {
  local label="$1"
  local mimes_csv="$2"
  IFS=',' read -r -a mimes <<<"$mimes_csv"
  local primary="${mimes[0]}"
  local cur desk choice line name
  cur="$(current_default "$primary")"
  cur_name="$(desktop_name "${cur:-}")"

  mapfile -t lines < <(list_handlers "$primary")
  if [[ ${#lines[@]} -eq 0 ]]; then
    toast "Nenhum app encontrado para $primary"
    return
  fi

  local opts=()
  opts+=("Atual: ${cur_name} (${cur:-—})")
  local l
  for l in "${lines[@]}"; do
    name="${l%%$'\t'*}"
    desk="${l#*$'\t'}"
    opts+=("${name}  ·  ${desk}")
  done
  opts+=("Cancelar")

  choice=$(printf '%s\n' "${opts[@]}" | "$PICKER" -p "$label")
  [[ -z "${choice:-}" || "$choice" == Cancelar || "$choice" == Atual:* ]] && return

  desk="${choice##*· }"
  desk="$(echo "$desk" | sed 's/^ *//;s/ *$//')"
  [[ "$desk" == *.desktop ]] || return
  set_defaults "$desk" "${mimes[@]}"
}

# Extensão → MIME → escolher app
by_extension() {
  local ext mime cur choice desk
  ext=$(printf '%s\n' \
    "pdf" "png" "jpg" "webp" "gif" "svg" "mp4" "mkv" "webm" "mp3" "flac" "wav" \
    "txt" "md" "json" "js" "ts" "css" "py" "rs" "go" "zip" "7z" "rar" "docx" "xlsx" "html" \
    | "$PICKER" -p "Extensão")
  [[ -z "${ext:-}" ]] && return
  ext="${ext#.}"
  tmp=$(mktemp "/tmp/barista-mime-XXXXXX.${ext}")
  mime=$(xdg-mime query filetype "$tmp" 2>/dev/null || true)
  rm -f "$tmp"
  if [[ -z "$mime" ]]; then
    mime=$(python3 - "$ext" <<'PY'
import mimetypes, sys
mimetypes.init()
ext = sys.argv[1]
if not ext.startswith("."):
    ext = "." + ext
print(mimetypes.types_map.get(ext.lower()) or "")
PY
)
  fi
  [[ -z "$mime" ]] && { toast "MIME desconhecido para .$ext"; return; }
  pick_app_for_mimes ".${ext} (${mime})" "$mime"
}

show_overview() {
  local lines=() entry label mimes primary cur
  for entry in "${CATEGORIES[@]}"; do
    label="${entry%%|*}"
    mimes="${entry#*|}"
    primary="${mimes%%,*}"
    cur="$(current_default "$primary")"
    lines+=("${label}  →  $(desktop_name "${cur:-}")")
  done
  printf '%s\n' "${lines[@]}" | "$PICKER" -p "Resumo (Enter = voltar)" >/dev/null || true
}

custom_mime() {
  local mime desk choice
  mime=$(printf '%s\n' \
    "Digite o MIME na próxima tela (ex: application/pdf)" \
    "Cancelar" | "$PICKER" -p "MIME custom")
  [[ -z "${mime:-}" || "$mime" == Cancelar ]] && return
  # fuzzel can't free-type easily — use a small zenity/dms or common list
  mime=$(printf '%s\n' \
    "application/pdf" "text/plain" "text/markdown" "image/png" "inode/directory" \
    "x-scheme-handler/http" "application/zip" "application/json" \
    | "$PICKER" -p "Escolha o MIME")
  [[ -z "${mime:-}" ]] && return
  pick_app_for_mimes "$mime" "$mime"
}

main_menu() {
  while true; do
    local choice entry label mimes
    choice=$(printf '%s\n' \
      "📋 Ver resumo atual" \
      "🧩 Por categoria…" \
      "📎 Por extensão (.pdf, .png…)" \
      "⌨️  MIME customizado" \
      "📂 Abrir mimeapps.list" \
      "Sair" \
      | "$PICKER" -p "Apps padrão")
    case "$choice" in
      "📋 Ver resumo atual") show_overview ;;
      "🧩 Por categoria…")
        choice=$(printf '%s\n' "${CATEGORIES[@]%%|*}" "Voltar" | "$PICKER" -p "Categoria")
        [[ -z "${choice:-}" || "$choice" == Voltar ]] && continue
        for entry in "${CATEGORIES[@]}"; do
          label="${entry%%|*}"
          mimes="${entry#*|}"
          if [[ "$label" == "$choice" ]]; then
            pick_app_for_mimes "$label" "$mimes"
            break
          fi
        done
        ;;
      "📎 Por extensão (.pdf, .png…)") by_extension ;;
      "⌨️  MIME customizado") custom_mime ;;
      "📂 Abrir mimeapps.list")
        mkdir -p "$(dirname "$MIMEAPPS")"
        touch "$MIMEAPPS"
        xdg-open "$MIMEAPPS" >/dev/null 2>&1 || thunar "$(dirname "$MIMEAPPS")" &
        ;;
      "Sair"|"") return ;;
    esac
  done
}

main_menu
