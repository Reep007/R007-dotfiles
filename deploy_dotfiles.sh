#!/bin/bash

# Exit if $HOME is not set
if [[ -z "$HOME" ]]; then
    echo "Error: \$HOME is not set"
    exit 1
fi

# Define source directory for dotfiles (adjust to your repo path)
DOTFILES_SRC="$HOME/Reep-sDot-s"  # Change this if your repo is elsewhere, e.g., "$HOME/.dotfiles"

# Define files/folders to copy and their target locations
declare -A DOTFILES=(
    ["$DOTFILES_SRC/.bash_profile"]="$HOME/.bash_profile"
    ["$DOTFILES_SRC/.bashrc"]="$HOME/.bashrc"
    ["$DOTFILES_SRC/.fehbg"]="$HOME/.fehbg"
    ["$DOTFILES_SRC/.gitconfig"]="$HOME/.gitconfig"
    ["$DOTFILES_SRC/.gtkrc-2.0"]="$HOME/.gtkrc-2.0"
    ["$DOTFILES_SRC/.poshtheme.json"]="$HOME/.poshtheme.json"
    ["$DOTFILES_SRC/.xprofile"]="$HOME/.xprofile"
    ["$DOTFILES_SRC/.zprofile"]="$HOME/.zprofile"
    ["$DOTFILES_SRC/.zshrc"]="$HOME/.zshrc"
    ["$DOTFILES_SRC/apply_pywal_blender.py"]="$HOME/.local/bin/apply_pywal_blender.py"
    ["$DOTFILES_SRC/reepfetch.sh"]="$HOME/.local/bin/reepfetch.sh"
    ["$DOTFILES_SRC/.config/waybar"]="$HOME/.config/waybar"
    ["$DOTFILES_SRC/.config/hypr"]="$HOME/.config/hypr"
)

# Function to copy dotfiles with overwrite
copy_dotfiles() {
    echo "Copying dotfiles..."
    for src in "${!DOTFILES[@]}"; do
        target="${DOTFILES[$src]}"
        if [[ -e "$src" ]]; then
            # Create parent directory for target if it doesn’t exist
            mkdir -p "$(dirname "$target")"
            # Copy with overwrite (-f to force)
            if cp -rf "$src" "$target"; then
                echo "Copied $src to $target"
            else
                echo "Error: Failed to copy $src to $target"
            fi
        else
            echo "Skipped $src (does not exist)"
        fi
    done
}

# Function to update CSS files in Waybar
update_css_files() {
    echo "Updating CSS files..."
    # Find all .css files in the Waybar directory
    CSS_FILES=()
    while IFS= read -r -d '' file; do
        CSS_FILES+=("$file")
    done < <(find "$HOME/.config/waybar" -type f -name "*.css" -print0)

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
        # Replace {HOME}, {$HOME}, and /{HOME} with the actual $HOME path
        if sed -e "s|{HOME}|$HOME|g" -e "s|{\$HOME}|$HOME|g" -e "s|/{HOME}|$HOME|g" "$CSS_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$CSS_FILE"; then
            echo "Updated $CSS_FILE"
            echo "Changes made:"
            grep "/home/reep" "$CSS_FILE" || echo "  No replacements found"
        else
            echo "Error: Failed to update $CSS_FILE"
        fi
    done
}

# Main execution
echo "Starting dotfiles deployment and CSS update..."

# Step 1: Copy dotfiles with overwrite
copy_dotfiles

# Step 2: Update CSS files
update_css_files

# Step 3: Set permissions for Waybar configs
if [[ -d "$HOME/.config/waybar" ]]; then
    chmod -R u+rw "$HOME/.config/waybar"
    echo "Set permissions for $HOME/.config/waybar"
fi

# Step 4: Restart Waybar to apply changes
echo "Restarting Waybar..."
pkill waybar
waybar &> /dev/null &

echo "Deployment complete!"
