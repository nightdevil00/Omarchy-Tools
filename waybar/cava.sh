#!/bin/bash

CONFIG="$HOME/.config/cava/waybar.conf"

pgrep -f "cava -p" >/dev/null || cava -p "$CONFIG" >/dev/null 2>&1 &

sleep 0.5

while IFS= read -r line; do
  cleaned="${line//;/ }"
  bars=""

  for n in $cleaned; do
    if [[ "$n" =~ ^[0-9]+$ ]]; then
      level=$(( 10#$n / 100 ))
      (( level > 10 || level < 0 )) && level=10
      
      blocks=(" " "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "█" "█")
      bar="${blocks[$level]}"
      
      if (( level <= 2 )); then
        color="#5e81ac"
      elif (( level <= 4 )); then
        color="#88c0d0"
      elif (( level <= 6 )); then
        color="#a3be8c"
      elif (( level <= 8 )); then
        color="#ebcb8b"
      else
        color="#bf616a"
      fi
      
      bars+="<span color='$color'>$bar</span>"
    fi
  done

  echo "{\"text\": \"$bars\"}"
done < <(cava -p "$CONFIG" 2>/dev/null)