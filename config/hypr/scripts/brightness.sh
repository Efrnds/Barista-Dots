#!/bin/bash

# Altera o brilho
case $1 in
    up)
        brightnessctl set 5%+
        ;;
    down)
        brightnessctl set 5%-
        ;;
esac

# Pega o brilho atual
CURR=$(brightnessctl g)
MAX=$(brightnessctl m)
PERC=$(( CURR * 100 / MAX ))

BAR=""
NUM_CHARS=$((PERC / 10))
for i in {1..10}; do
    if [ $i -le $NUM_CHARS ]; then
        BAR="${BAR}█"
    else
        BAR="${BAR}░"
    fi
done

notify-send -u low -h string:x-canonical-private-synchronous:brightness -t 1000 -i display-brightness "Brilho: ${PERC}%" "$BAR"
