#!/usr/bin/env bash
# Emoji picker via fuzzel, copies to clipboard
PICKER="$HOME/.config/hypr/scripts/picker.sh"

chosen=$(cat <<'EOF' | "$PICKER" -p "Emoji"
😀 Sorriso
😂 Rindo
🥰 Apaixonado
😎 Cool
🤔 Pensando
😭 Chorando
🔥 Fogo
✨ Brilho
❤️ Coração
💜 Roxo
👍 Joinha
👎 Negativo
🎉 Festa
🚀 Foguete
💻 Computador
🧠 Cérebro
🌙 Lua
⭐ Estrela
✅ Check
❌ X
⚠️ Alerta
💡 Ideia
📌 Pin
🎵 Música
📸 Foto
🙏 Obrigado
🤝 Aperto
💯 100
EOF
)

[[ -n "$chosen" ]] && printf '%s' "${chosen%% *}" | wl-copy && notify-send -t 1000 "Emoji copiado" "${chosen%% *}"
