# ~/.bashrc

# Auto-start Zsh — SOMENTE shell interativo.
# NÃO usar só `[ -t 1 ]`: o niri-session faz `bash -l -c ...` com TTY e
# o exec zsh quebrava a cadeia → CLI preto.
if [[ $- == *i* ]] && [ -n "${BASH_VERSION:-}" ] && [ -z "${BARISTA_NIRI_BOOTSTRAPPED:-}" ] && [ -z "${NIRI_SOCKET:-}" ]; then
  if command -v zsh >/dev/null 2>&1; then
    export TERMINAL="${TERMINAL:-alacritty}"
    export EDITOR="${EDITOR:-nvim}"
    exec zsh
  fi
fi

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export TERMINAL="${TERMINAL:-alacritty}"
export EDITOR="${EDITOR:-nvim}"

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias cursor="${HOME}/Applications/cursor.AppImage"
