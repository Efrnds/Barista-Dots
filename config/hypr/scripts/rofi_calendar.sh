#!/bin/bash

# Calendário interativo simples via Rofi com alinhamento monoespaçado

CAL_DATA=$(cal)

# Adiciona um pequeno recuo para centralizar melhor os números
CAL_FORMATADO=$(echo "$CAL_DATA" | sed 's/^/ /')

echo -e "$CAL_FORMATADO" | rofi -dmenu -p "📅 Calendário" -i \
    -theme-str 'window {width: 20%;} listview {lines: 8;} element {font: "JetBrainsMono Nerd Font Bold 12";}'
