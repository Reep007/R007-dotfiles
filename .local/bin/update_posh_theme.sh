#!/bin/bash

# Paths
ORIGINAL_THEME="/usr/share/oh-my-posh/themes/atomic.omp.json"
CUSTOM_THEME="$HOME/.config/oh-my-posh/themes/pywal-atomic.omp.json"
COLORS_JSON="$HOME/.cache/wal/colors.json"

# Ensure output directory exists
mkdir -p "$(dirname "$CUSTOM_THEME")"

# Brightness function
get_brightness() {
    hex=$1
    hex=${hex#\#}
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    brightness=$(echo "scale=0; ($r * 0.299 + $g * 0.587 + $b * 0.114)" | bc)
    echo $brightness
}

# Extract pywal colors
background=$(jq -r '.special.background' "$COLORS_JSON")
foreground=$(jq -r '.special.foreground' "$COLORS_JSON")
color8=$(jq -r '.colors.color8' "$COLORS_JSON")  # Path
color2=$(jq -r '.colors.color2' "$COLORS_JSON")  # Shell
color1=$(jq -r '.colors.color1' "$COLORS_JSON")  # Execution time
color5=$(jq -r '.colors.color5' "$COLORS_JSON")  # Secondary prompt text (╰─)
color6=$(jq -r '.colors.color6' "$COLORS_JSON")  # Git

# Start with the original theme
cp "$ORIGINAL_THEME" "$CUSTOM_THEME"

# Update 'path' segment
jq --arg bg "$color8" \
   '(.blocks[].segments[] | select(.type == "path") | .background) = $bg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
brightness=$(get_brightness "$color8")
if (( $(echo "$brightness < 128" | bc -l) )); then
    fg="#ffffff"
else
    fg="#000000"
fi
jq --arg fg "$fg" \
   '(.blocks[].segments[] | select(.type == "path") | .foreground) = $fg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"

# Update 'shell' segment
jq --arg bg "$color2" \
   '(.blocks[].segments[] | select(.type == "shell") | .background) = $bg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
jq \
   '(.blocks[].segments[] | select(.type == "shell") | .template) = " \uf11c Neo "' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
brightness=$(get_brightness "$color2")
if (( $(echo "$brightness < 128" | bc -l) )); then
    fg="#ffffff"
else
    fg="#000000"
fi
jq --arg fg "$fg" \
   '(.blocks[].segments[] | select(.type == "shell") | .foreground) = $fg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"

# Update 'execution_time' segment
jq --arg bg "$color1" \
   '(.blocks[].segments[] | select(.type == "executiontime") | .background) = $bg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
jq \
   '(.blocks[].segments[] | select(.type == "executiontime") | .template) = " \udb82\udfc9  {{ .FormattedMs }}\u2000\ue231 "' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
brightness=$(get_brightness "$color1")
if (( $(echo "$brightness < 128" | bc -l) )); then
    fg="#ffffff"
else
    fg="#000000"
fi
jq --arg fg "$fg" \
   '(.blocks[].segments[] | select(.type == "executiontime") | .foreground) = $fg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"

# Update 'text' segment for secondary prompt (╰─)
jq --arg fg "$color5" \
   '(.blocks[].segments[] | select(.template == "\u2570\u2500") | .foreground) = $fg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"

# Update 'git' segment
jq --arg bg "$color6" \
   '(.blocks[].segments[] | select(.type == "git") | .background) = $bg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
jq '(.blocks[].segments[] | select(.type == "git") | .background_templates) = []' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"
brightness=$(get_brightness "$color6")
if (( $(echo "$brightness < 128" | bc -l) )); then
    fg="#ffffff"
else
    fg="#000000"
fi
jq --arg fg "$fg" \
   '(.blocks[].segments[] | select(.type == "git") | .foreground) = $fg' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"

# Remove right-aligned block (os, time, etc.)
jq 'del(.blocks[] | select(.alignment == "right"))' \
   "$CUSTOM_THEME" > tmp.json && mv tmp.json "$CUSTOM_THEME"

echo "Updated Oh My Posh theme at $CUSTOM_THEME"
