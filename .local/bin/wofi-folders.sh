#!/bin/bash

# Folders to display
FOLDERS=(
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/Pictures"
)

# List folders, pipe to Wofi with 2 columns
SELECTED=$(for folder in "${FOLDERS[@]}"; do
    basename "$folder"
done | wofi --show dmenu --prompt "Select a folder" --width=400 --height=150 --columns=2)

# Open selected folder
if [ -n "$SELECTED" ]; then
    for folder in "${FOLDERS[@]}"; do
        if [ "$(basename "$folder")" = "$SELECTED" ]; then
            thunar "$folder"
        fi
    done
fi
