#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"
HYPRPAPER_CONFIG="$HOME/.config/hypr/hyprpaper.conf"

# Get list of wallpapers and show in wofi
selected_wallpaper=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" \) -printf "%f\n" | \
    wofi --dmenu --width 500 --height 400 \
    --prompt "Select Wallpaper" \
    --cache-file=/dev/null \
    --style ~/.config/wofi/style.css)

# If a wallpaper was selected
if [ -n "$selected_wallpaper" ]; then
    full_path="$WALLPAPER_DIR/$selected_wallpaper"
    
    # Update hyprpaper config
    sed -i "s|^preload = .*$|preload = $full_path|" "$HYPRPAPER_CONFIG"
    sed -i "s|^wallpaper = .*$|wallpaper = eDP-1,$full_path|" "$HYPRPAPER_CONFIG"
    
    # Reload hyprpaper
    killall hyprpaper
    hyprpaper >/dev/null 2>&1 &
fi