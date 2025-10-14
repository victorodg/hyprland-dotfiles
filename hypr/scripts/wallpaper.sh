#!/bin/bash

CONFIG_FILE="$HOME/.config/hypr/hyprpaper.conf"
WALLPAPERS_DIR="$HOME/Pictures/wallpapers"

# Select wallpaper using wofi
selected=$(find "$WALLPAPERS_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) -printf "%f\n" | \
    wofi --dmenu \
    --prompt "Select Wallpaper" \
    --width 500 \
    --height 400 \
    --cache-file=/dev/null \
    --style ~/.config/wofi/style.css)

if [ -n "$selected" ]; then
    wallpaper="$WALLPAPERS_DIR/$selected"
    
    # Update hyprpaper config
    sed -i "s|^preload = .*|preload = $wallpaper|" "$CONFIG_FILE"
    sed -i "s|^wallpaper = .*|wallpaper = eDP-1,$wallpaper|" "$CONFIG_FILE"
    
    # Restart hyprpaper
    killall hyprpaper
    hyprpaper > /dev/null 2>&1 &
fi