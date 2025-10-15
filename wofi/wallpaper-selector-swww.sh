#!/bin/bash

# Wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Find all image files recursively (including GIFs for animations)
WALLPAPERS=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | sort)

# Use wofi to select a wallpaper with image preview
SELECTED=$(echo "$WALLPAPERS" | while read -r path; do
    echo "img:$path:text:$path"
done | wofi --dmenu --prompt "Select Wallpaper" --width 1000 --height 600 --allow-images --image-size 256 --columns 1 | sed 's/.*text://')

# If a wallpaper was selected, set it with swww
if [ -n "$SELECTED" ]; then
    FULL_PATH="$SELECTED"
    
    # Set wallpaper with swww (supports static images and animated GIFs)
    swww img "$FULL_PATH" --transition-type fade --transition-duration 2
    
    # Send notification
    notify-send "Wallpaper Changed" "$(basename "$FULL_PATH")"
fi
