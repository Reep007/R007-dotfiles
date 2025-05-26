#!/usr/bin/env bash
#
# volume-slider.sh
# A simple Rofi “slider” to pick volume in 0–100% steps

# Rofi theme (optional — drop “-theme …” if you want default)
THEME="$HOME/.config/rofi/volume-slider.rasi"

# Get current volume (integer 0–100)
current=$(pactl get-sink-volume @DEFAULT_SINK@ \
           | awk '{ print $5 }' | sed 's/%//')

# Build list of numbers 0,5,10,…,100
options="$(seq 0 5 100)"

# Launch Rofi dmenu, pre-prompt shows current value
choice=$(echo "$options" \
  | rofi -dmenu -p "Volume: ${current}%" \
         -format F \
         -theme "$THEME")

# If user picked something, apply it
if [[ -n "$choice" ]]; then
  pactl set-sink-volume @DEFAULT_SINK@ "${choice}%"
  # optional notification
  notify-send -h int:value:"$choice" "Volume" "${choice}%"
fi
