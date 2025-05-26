#!/bin/bash

# Setup logging
LOGFILE="/tmp/switch_wallpaper.log"
echo "$(date): Starting switch_wallpaper.sh" >> "$LOGFILE"

# Folder containing your wallpapers
WALLPAPER_DIR="$HOME/Wallpaper"

# File to store the current index
INDEX_FILE="$HOME/.cache/wallpaper_index"

# Validate wallpaper directory
if [[ ! -d "$WALLPAPER_DIR" ]]; then
    echo "$(date): Error: Wallpaper directory $WALLPAPER_DIR does not exist" >> "$LOGFILE"
    exit 1
fi

# Get list of wallpapers (sorted numerically)
WALLPAPERS=($(ls -1v "$WALLPAPER_DIR"/wall[0-9]* 2>/dev/null | grep -E 'wall[0-9]+\.(jpg|png)$'))
if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
    echo "$(date): Error: No wallpapers found in $WALLPAPER_DIR" >> "$LOGFILE"
    exit 1
fi
echo "$(date): Found ${#WALLPAPERS[@]} wallpapers" >> "$LOGFILE"

# Total number of wallpapers
TOTAL=${#WALLPAPERS[@]}

# Check if a wallpaper path is provided as an argument
if [[ -n "$1" && -f "$1" ]]; then
    WALLPAPER="$1"
    INDEX=0
    for i in "${!WALLPAPERS[@]}"; do
        if [[ "${WALLPAPERS[$i]}" == "$WALLPAPER" ]]; then
            INDEX=$((i + 1))
            break
        fi
    done
    if [[ $INDEX -eq 0 ]]; then
        INDEX=0
    fi
else
    if [[ -f "$INDEX_FILE" ]]; then
        INDEX=$(cat "$INDEX_FILE")
    else
 GRAND       INDEX=0
    fi
    WALLPAPER="${WALLPAPERS[$INDEX]}"
    ((INDEX=INDEX+1))
    if [[ $INDEX -ge $TOTAL ]]; then
        INDEX=0
    fi
fi

# Save new index
echo "$INDEX" > "$INDEX_FILE"
echo "$(date): Selected wallpaper: $WALLPAPER" >> "$LOGFILE"

# Backup and generate Hyprpaper config
cp ~/.config/hypr/hyprpaper.conf ~/.config/hypr/hyprpaper.conf.bak 2>/dev/null || true
echo "preload = $WALLPAPER" > ~/.config/hypr/hyprpaper.conf
echo "wallpaper = ,$WALLPAPER" >> ~/.config/hypr/hyprpaper.conf
echo "$(date): Hyprpaper config updated" >> "$LOGFILE"

# Restart Hyprpaper
pkill -u $USER hyprpaper 2>/dev/null
hyprpaper & disown
echo "$(date): Hyprpaper restarted" >> "$LOGFILE"

# Clear Pywal templates to avoid corruption
rm -rf ~/.cache/wal/templates/* 2>/dev/null
echo "$(date): Cleared Pywal templates" >> "$LOGFILE"

# Apply Pywal colors
if ! wal -i "$WALLPAPER" -e &>/tmp/wal_error.log; then
    echo "Warning: wal failed, using cached colors" >&2
    echo "$(date): Pywal failed, see /tmp/wal_error.log" >> "$LOGFILE"
    cat /tmp/wal_error.log >> "$LOGFILE"
    if [[ ! -f ~/.cache/wal/colors.sh ]]; then
        echo "Error: No cached colors available" >&2
        echo "$(date): No cached colors available" >> "$LOGFILE"
    fi
else
    echo "$(date): Pywal applied" >> "$LOGFILE"
fi

# Update Thunar colors
if source ~/.cache/wal/colors.sh 2>/dev/null; then
    sed -i "s/BG=.*/BG=${color5:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/FG=.*/FG=${color0:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/MENU_BG=.*/MENU_BG=${color5:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/MENU_FG=.*/MENU_FG=${color0:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/SEL_BG=.*/SEL_BG=${color4:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/SEL_FG=.*/SEL_FG=${color7:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/TXT_BG=.*/TXT_BG=${color5:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/TXT_FG=.*/TXT_FG=${color0:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/BTN_BG=.*/BTN_BG=${color6:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/BTN_FG=.*/BTN_FG=${color0:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/HDR_BTN_BG=.*/HDR_BTN_BG=${color3:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    sed -i "s/HDR_BTN_FG=.*/HDR_BTN_FG=${color7:1}/" ~/.cache/wal/colors-oomox 2>/dev/null
    echo "$(date): Thunar colors updated via colors-oomox" >> "$LOGFILE"
else
    echo "Warning: Failed to source colors.sh" >&2
    echo "$(date): Failed to source colors.sh" >> "$LOGFILE"
fi

# Apply Thunar settings
~/update_pywal_icons.sh 2>/dev/null
xfconf-query -c xsettings -p /Net/IconThemeName -s pywal-custom 2>/dev/null
gsettings set org.gnome.desktop.interface icon-theme 'pywal-custom' 2>/dev/null
echo "$(date): Thunar icon theme set to pywal-custom" >> "$LOGFILE"

# Generate and apply GTK theme
oomox-cli -o oomox-xresources ~/.cache/wal/colors-oomox 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "oomox-xresources" 2>/dev/null
echo "$(date): GTK theme applied" >> "$LOGFILE"


# Refresh Thunar if running
if pgrep -u $USER thunar >/dev/null; then
    pkill -u $USER -HUP thunar 2>/dev/null || true
    echo "$(date): Thunar refreshed (if running)" >> "$LOGFILE"
else
    echo "$(date): Thunar not running, no refresh needed" >> "$LOGFILE"
fi

# Update Waybar colors
cat ~/.cache/wal/colors-waybar.css > ~/.config/waybar/colors.css 2>/dev/null
echo "$(date): Waybar colors updated" >> "$LOGFILE"

# Reload Waybar
pkill -u $USER waybar 2>/dev/null
waybar & disown
echo "$(date): Waybar reloaded" >> "$LOGFILE"

# Update Oh My Posh theme
~/bin/update_posh_theme.sh 2>/dev/null
echo "$(date): Oh My Posh theme updated" >> "$LOGFILE"

# Update Hyprland borders
if source ~/.cache/wal/colors.sh 2>/dev/null; then
    sed -i "/col.active_border/c\    col.active_border = rgba(${color2:1}ff) rgba(${color6:1}ff) 35deg" ~/.config/hypr/hyprland.conf 2>/dev/null
    sed -i "/col.inactive_border/c\    col.inactive_border = rgba(${color8:1}ff) 45deg" ~/.config/hypr/hyprland.conf 2>/dev/null
    echo "$(date): Hyprland borders updated" >> "$LOGFILE"
fi

# Update Wofi
mkdir -p ~/.config/wofi
if source ~/.cache/wal/colors.sh 2>/dev/null; then
    cat > ~/.config/wofi/style.css << EOL
@define-color background #${color0:1};
@define-color foreground #${color7:1};
@define-color accent #${color4:1};
@define-color urgent #${color4:1};

window {
    margin: 20px;
    border: 1px solid @accent;
    border-radius: 25px;
    background-image: url("file://$WALLPAPER");
    background-size: cover;
    background-repeat: no-repeat;
    background-position: center;
    background-clip: padding-box;
    background-color: rgba(0, 0, 0, 0.8);
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
    padding: 5px;
}

#input {
    margin: 40px 20px;
    padding: 5px;
    border-radius: 20px;
    background-color: rgba(26, 26, 26, 0.6);
    color: @foreground;
    border: none;
}

#entry {
    margin: 5px 5px;
    padding: 1px;
    border-radius: 20px;
    background-color: rgba(45, 45, 45, 0.0);
    color: @foreground;
}

#entry:selected {
    background-color: @accent;
    color: @foreground;
    border: none;
    outline: none;
}

#entry flowboxchild {
    min-width: 100px;
}

#scroll {
    margin: 25px;
}

#text {
    color: @foreground;
}

#text:selected {
    background-color: transparent;
    color: @background;
    border: none;
    outline: none;
}

#img {
    background-color: transparent;
    padding: 2px;
    margin: 2px;
}

#img:selected {
    background-color: transparent;
    color: @foreground;
}
EOL
    echo "$(date): Wofi style updated" >> "$LOGFILE"
fi

# Set custom folder icons
gio set "$HOME/Documents" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-documents.svg" 2>/dev/null
gio set "$HOME/Downloads" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-download.svg" 2>/dev/null
gio set "$HOME/Pictures" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-pictures.svg" 2>/dev/null
gio set "$HOME/Music" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-music.svg" 2>/dev/null
gio set "$HOME/Videos" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-videos.svg" 2>/dev/null
gio set "$HOME/Templates" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-templates.svg" 2>/dev/null
gio set "$HOME/Public" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-publicshare.svg" 2>/dev/null
gio set "$HOME/Desktop" metadata::custom-icon "file:///home/neo/.icons/pywal-custom/scalable/places/folder-desktop.svg" 2>/dev/null
echo "$(date): Folder icons updated" >> "$LOGFILE"

# reload Obsidian
~/.config/obsidian-pywal/update.sh

# Reload Hyprland config
hyprctl reload 2>/dev/null
echo "$(date): Hyprland config reloaded" >> "$LOGFILE"

# Generate and apply GTK theme uncommom # if background color not black
# oomox-cli -o oomox-xresources ~/.cache/wal/colors-oomox >> "$LOGFILE" 2>&1
# gsettings set org.gnome.desktop.interface gtk-theme "oomox-xresources" 2>/dev/null

# Link GTK4 theme
mkdir -p ~/.config/gtk-4.0
ln -sf ~/.themes/oomox-xresources/gtk-4.0 ~/.config/gtk-4.0

echo "$(date): GTK theme applied (GTK2/3/4)" >> "$LOGFILE"




# Ensure script exits with 0 if wallpaper was applied
echo "$(date): Script completed" >> "$LOGFILE"
exit 0
