# ~/.zprofile
# NÃO rodar no caminho de autologin (greetd initial_session → niri-session-fast).
# Só recupera se você caiu em shell sem compositor.

if [[ -z ${WAYLAND_DISPLAY:-} && -z ${DISPLAY:-} && -z ${BARISTA_NIRI_BOOTSTRAPPED:-} ]]; then
  # só se for TTY interativo de verdade (não session start silencioso)
  if [[ -o interactive && -t 1 ]]; then
    parent=$(ps -o comm= -p "${PPID:-0}" 2>/dev/null | tr -d ' ')
    if [[ "$parent" == *greetd* || ${DESKTOP_SESSION:-} == niri || ${XDG_SESSION_DESKTOP:-} == niri ]]; then
      export BARISTA_NIRI_BOOTSTRAPPED=1
      exec /home/eduardo/.local/bin/niri-session-fast
    fi
  fi
fi
