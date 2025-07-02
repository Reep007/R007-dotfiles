#!/bin/zsh

# Enable nullglob to prevent errors on unmatched globs
setopt nullglob

# Setup logging
LOGFILE="$HOME/.cache/reepfetch.log"
mkdir -p "$HOME/.cache" 2>/dev/null
echo "$(date): Starting reepfetch.sh" >> "$LOGFILE"

# Get terminal size
cols=$(tput cols)
rows=$(tput lines)

# Define image properties
img_width=27  # Adjust as needed
img_height=30  # Adjust as needed

# Calculate positions
center_x=$(( (cols - text_width) / 2 ))  # Center horizontally
center_y=$(( (rows - img_height) / 2 ))  # Center vertically
img_x_offset=0  # Shift left from center
img_y_offset=0  # Align with text box

# Directory for images
IMG_DIR="$HOME/Pic4_terminal"

# Select a random image from IMG_DIR using find
IMG_FILE=""
if [[ -d "$IMG_DIR" ]]; then
    # Use find to list image files and select one randomly
    IMG_FILES=($(find "$IMG_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null))
    if [[ ${#IMG_FILES[@]} -gt 0 ]]; then
        # Select a random image
        IMG_FILE=${IMG_FILES[$((RANDOM % ${#IMG_FILES[@]} + 1))]}
        echo "$(date): Found ${#IMG_FILES[@]} images, selected: $IMG_FILE" >> "$LOGFILE"
    else
        echo "$(date): Warning: No images (.png, .jpg, .jpeg) found in $IMG_DIR" >> "$LOGFILE"
    fi
else
    echo "$(date): Warning: Image directory $IMG_DIR does not exist" >> "$LOGFILE"
fi

# Fallback to default image if no image was selected
if [[ -z "$IMG_FILE" || ! -f "$IMG_FILE" ]]; then
    IMG_FILE="$HOME/Pic4_terminal/Arch.png"
    if [[ ! -f "$IMG_FILE" ]]; then
        echo "$(date): Warning: Fallback image $IMG_FILE does not exist" >> "$LOGFILE"
        IMG_FILE=""  # No image will be displayed
    else
        echo "$(date): Using fallback image: $IMG_FILE" >> "$LOGFILE"
    fi
fi

# Get system info
USERNAME=$USER
UPTIME=$(uptime -p | sed 's/up //')

# Calculate days since OS installation
INSTALL_TIMESTAMP=$(stat -c %Y / 2>/dev/null || echo 0)
CURRENT_TIMESTAMP=$(date +%s)
if [ "$INSTALL_TIMESTAMP" -eq 0 ]; then
  DAYS_UP="unknown (could not determine install date)"
elif [ "$CURRENT_TIMESTAMP" -lt "$INSTALL_TIMESTAMP" ]; then
  DAYS_UP="error (install date in future)"
else
  SECONDS_SINCE_INSTALL=$((CURRENT_TIMESTAMP - INSTALL_TIMESTAMP))
  DAYS=$((SECONDS_SINCE_INSTALL / 86400))
  if [ "$DAYS" -eq 0 ]; then
    DAYS_UP="less than 1 day"
  elif [ "$DAYS" -lt 365 ]; then
    DAYS_UP="$DAYS days"
  else
    YEARS=$((DAYS / 365))
    REMAINING_DAYS=$((DAYS % 365))
    if [ "$YEARS" -eq 1 ]; then
      DAYS_UP="$YEARS year $REMAINING_DAYS days"
    else
      DAYS_UP="$YEARS years $REMAINING_DAYS days"
    fi
  fi
fi

DISTRO=$(lsb_release -ds 2>/dev/null || grep -Po '(?<=^PRETTY_NAME=")[^"]*' /etc/os-release)
KERNEL=$(uname -r)
TERMINAL=$TERM
SHELL=$(basename $SHELL)
CPU=$(grep "model name" /proc/cpuinfo | head -1 | cut -d ":" -f2- | sed 's/^[[:space:]]*//')

GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n 1)
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n 1)
GPU_UTIL=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n 1)
GPU="$GPU_NAME ($GPU_TEMP°C, $GPU_UTIL%)"

DISK_USAGE=$(df -h /home | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')

MEM_USED=$(free -m | awk 'NR==2 {print $3}')
MEM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
MEM_PERCENT=$(awk "BEGIN {printf \"%.1f%%\", $MEM_USED/$MEM_TOTAL*100}")
MEMORY_USAGE="${MEM_USED}MB / ${MEM_TOTAL}MB (${MEM_PERCENT})"

# Load Pywal colors
source "${HOME}/.cache/wal/colors.sh" 2>> "$LOGFILE"

# Set a static color for the box
BOX_COLOR="\e[37m"  # White
RESET="\e[0m"       # Reset color

# Convert Hex to RGB ANSI for Truecolor Terminals
hex_to_rgb() {
    HEX=$(echo "$1" | sed 's/#//')
    R=$((16#${HEX:0:2}))
    G=$((16#${HEX:2:2}))
    B=$((16#${HEX:4:2}))
    printf "\e[38;2;%d;%d;%dm" "$R" "$G" "$B"
}

# Assign ANSI colors for text
C1=$(hex_to_rgb "$color1")
C2=$(hex_to_rgb "$color2")
C3=$(hex_to_rgb "$color3")
C4=$(hex_to_rgb "$color4")
C5=$(hex_to_rgb "$color5")
C6=$(hex_to_rgb "$color6")
C7=$(hex_to_rgb "$color7")

# Info Box with static box color and colored text
INFO_BOX="
                         ${BOX_COLOR}╭───────────╮${RESET}
                         ${BOX_COLOR}│${RESET} ${C1} user    ${RESET}${BOX_COLOR}│${RESET} $USERNAME
                         ${BOX_COLOR}│${RESET} ${C2}󰅐 uptime  ${RESET}${BOX_COLOR}│${RESET} $UPTIME
                         ${BOX_COLOR}│${RESET} ${C3} days up ${RESET}${BOX_COLOR}│${RESET} $DAYS_UP
                         ${BOX_COLOR}│${RESET} ${C4} distro  ${RESET}${BOX_COLOR}│${RESET} $DISTRO
                         ${BOX_COLOR}│${RESET} ${C5} kernel  ${RESET}${BOX_COLOR}│${RESET} $KERNEL
                         ${BOX_COLOR}│${RESET} ${C6} term    ${RESET}${BOX_COLOR}│${RESET} $TERMINAL
                         ${BOX_COLOR}│${RESET} ${C7} shell   ${RESET}${BOX_COLOR}│${RESET} $SHELL
                         ${BOX_COLOR}│${RESET} ${C1}󰍛 cpu     ${RESET}${BOX_COLOR}│${RESET} $CPU
                         ${BOX_COLOR}│${RESET} ${C2}󰘚 gpu     ${RESET}${BOX_COLOR}│${RESET} $GPU
                         ${BOX_COLOR}│${RESET} ${C3}󰉉 disk    ${RESET}${BOX_COLOR}│${RESET} $DISK_USAGE
                         ${BOX_COLOR}│${RESET} ${C4} memory  ${RESET}${BOX_COLOR}│${RESET} $MEMORY_USAGE
                         ${BOX_COLOR}├───────────┤${RESET}
                         ${BOX_COLOR}│${RESET} ${C5} colors  ${RESET}${BOX_COLOR}│${RESET} ${C1}● ${C2}● ${C3}● ${C4}● ${C5}● ${C6}● ${C7}●
                         ${BOX_COLOR}╰───────────╯${RESET}"

# Adjust position of system info box
tput cup 2 0  # Move cursor to row 2, column 0 for system info

# Calculate center position for text
text_width=15  # Approximate width of the system info box
center_x=$(( (cols - text_width) / 1 ))

# Adjust for image on the left
img_x_offset=$((center_x - img_width - 200 ))  # Space between image and text

# Vertical offset for image (adjust as needed)
img_y_offset=0  # Adjust how many lines down the image should appear

# Display random image using kitty icat (if an image was selected)
if [[ -n "$IMG_FILE" ]]; then
    kitty +kitten icat --clear  # Clear previous images
    kitty +kitten icat --place=${img_width}x${img_height}@${img_x_offset}x2 "$IMG_FILE" 2>> "$LOGFILE"
else
    echo "$(date): No image displayed" >> "$LOGFILE"
fi

# Print system info in the center
tput cup $((lines / 2 )) $center_x
echo -e "$INFO_BOX"

# Debug output (uncomment for troubleshooting)
#echo "Terminal Size: ${cols}x${rows}"
#echo "Image Position: ${img_x_offset}x${img_y_offset}"
#echo "Selected Image: $IMG_FILE"
