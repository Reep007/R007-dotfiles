#!/bin/bash
choice=$(echo -e "📁 Folders\0info\x1ffolders" | wofi --show dmenu,drun --combi-modes dmenu,drun --prompt "Launch" --cache-file=/dev/null)
if [ "$(echo "$choice" | grep -o 'info=folders')" = "info=folders" ]; then
    ~/.local/bin/wofi-folders.sh
fi
