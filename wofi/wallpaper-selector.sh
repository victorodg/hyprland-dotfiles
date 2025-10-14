#!/bin/bash

# Wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Find all image files recursively
WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

# Use wofi to select a wallpaper with image preview
SELECTED=$(echo "$WALLPAPERS" | while read -r path; do
    echo "img:$path:text:$path"
done | wofi --dmenu --prompt "Select Wallpaper" --width 1000 --height 600 --allow-images --image-size 256 --columns 1 | sed 's/.*text://')

# If a wallpaper was selected, use it directly
if [ -n "$SELECTED" ]; then
    FULL_PATH="$SELECTED"
    
    # Kill existing hyprpaper
    pkill hyprpaper
    
    # Get all monitors
    MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
    
    # Create temporary hyprpaper config
    CONFIG="$HOME/.config/hypr/hyprpaper.conf"
    
    # Backup existing config if it exists
    if [ -f "$CONFIG" ]; then
        cp "$CONFIG" "$CONFIG.backup"
    fi
    
    # Write new config
    echo "preload = $FULL_PATH" > "$CONFIG"
    
    # Set wallpaper for all monitors
    while IFS= read -r monitor; do
        echo "wallpaper = $monitor,$FULL_PATH" >> "$CONFIG"
    done <<< "$MONITORS"
    
    # Start hyprpaper with new config
    hyprpaper &
    
    # Send notification
    notify-send "Wallpaper Changed" "$(basename "$FULL_PATH")"
fi
