#!/bin/bash
if [[ -z "$HOME" ]]; then
    echo "Error: \$HOME is not set"
    exit 1
fi
CSS_FILES=(
    "$HOME/.config/waybar/style.css"
    "$HOME/.config/waybar/theme.css"
)
for CSS_FILE in "${CSS_FILES[@]}"; do
    if [[ ! -f "$CSS_FILE" ]]; then
        echo "Skipped $CSS_FILE (file does not exist)"
        continue
    fi
    if [[ ! -w "$CSS_FILE" ]]; then
        echo "Skipped $CSS_FILE (file is not writable)"
        continue
    fi
    TEMP_FILE="$CSS_FILE.temp"
    if sed -e "s|{HOME}|$HOME|g" -e "s|{\$HOME}|$HOME|g" "$CSS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$CSS_FILE"; then
        echo "Updated $CSS_FILE"
        echo "Changes made:"
        grep "/home/reep" "$CSS_FILE" || echo "  No replacements found in output"
    else
        echo "Error: Failed to update $CSS_FILE"
    fi
done
