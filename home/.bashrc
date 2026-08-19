# Auto-start Zsh
if [ -t 1 ] && [ -n "$BASH_VERSION" ]; then
    export TERMINAL="foot"
    export EDITOR="nvim"
    exec zsh
fi
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
alias cursor="${HOME}/Applications/cursor.AppImage"
