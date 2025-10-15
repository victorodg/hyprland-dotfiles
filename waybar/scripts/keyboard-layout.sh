#!/bin/bash

# Get current keyboard layout for niri
# Query the XKB state to determine current layout

# Try multiple methods to get the keyboard layout
layout=""

# Method 1: Try hyprctl for Hyprland (if available)
if command -v hyprctl &> /dev/null; then
    layout=$(hyprctl devices -j 2>/dev/null | jq -r '.keyboards[0].active_keymap' 2>/dev/null | cut -d' ' -f1)
fi

# Method 2: If not found, try reading from X11/Wayland keyboard state
if [ -z "$layout" ] || [ "$layout" = "null" ]; then
    # For Wayland compositors, check XKB environment
    if [ -n "$XDG_SESSION_TYPE" ] && [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        # Try to get from setxkbmap query (works if xwayland is running)
        layout=$(setxkbmap -query 2>/dev/null | grep layout | awk '{print $2}' | cut -d',' -f1)
    fi
fi

# Method 3: Parse from config as fallback
if [ -z "$layout" ] || [ "$layout" = "null" ]; then
    # Read from niri config
    layout=$(grep -E "^\s*layout\s+" ~/.config/niri/config.kdl 2>/dev/null | head -1 | sed 's/.*layout\s*"\([^,"]*\).*/\1/')
fi

# Default fallback
if [ -z "$layout" ] || [ "$layout" = "null" ]; then
    layout="us"
fi

# Convert layout codes to short names
case "$layout" in
    "English (US, intl., with dead keys)") layout="us_intl" ;;
    "Portuguese (Brazil)") layout="br" ;;
    *"intl"*) layout="us_intl" ;;
esac

# Output for waybar
echo "{\"text\": \"${layout}\", \"tooltip\": \"Keyboard Layout: ${layout}\", \"class\": \"keyboard-layout\"}"
