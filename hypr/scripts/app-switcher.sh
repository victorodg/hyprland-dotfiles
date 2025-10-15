#!/bin/bash

# Lock file to prevent multiple instances
LOCK_FILE="/tmp/hypr-app-switcher.lock"

# If lock exists, another instance is running - just exit
if [ -f "$LOCK_FILE" ]; then
    exit 0
fi

# Create lock file
touch "$LOCK_FILE"

# Clean up on exit
cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Get list of all windows across all workspaces, sorted by workspace
windows=$(hyprctl clients -j | jq -r 'sort_by(.workspace.id) | .[] | "\(.workspace.id)|\(.address)|\(.initialTitle)"')

if [ -z "$windows" ]; then
    notify-send "App Switcher" "No windows found"
    exit 0
fi

# Format for wofi with icons using desktop entries
formatted_list=""
declare -A entries

while IFS='|' read -r workspace address initialTitle; do
    # Create display text with just workspace and initial title
    display="[WS $workspace] $initialTitle"
    
    # Store mapping
    entries["$display"]="$address|$workspace"
    
    # Add to formatted list
    formatted_list+="$display"$'\n'
done <<< "$windows"

# Show in wofi with shorter width
selection=$(echo -n "$formatted_list" | wofi --dmenu --prompt "Switch to:" --width 400 --height 400 --style ~/.config/wofi/style.css --allow-images --allow-markup --cache-file=/dev/null)

if [ -z "$selection" ]; then
    exit 0
fi

# Get address and workspace from selection
IFS='|' read -r address workspace <<< "${entries[$selection]}"

# Switch to the workspace and focus the window
if [ -n "$address" ] && [ -n "$workspace" ]; then
    hyprctl dispatch workspace "$workspace" >/dev/null 2>&1
    sleep 0.05
    hyprctl dispatch focuswindow "address:$address" >/dev/null 2>&1
fi
