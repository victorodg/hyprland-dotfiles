#!/bin/bash

# Script to manage keyboard layout persistence in Hyprland
# Saves the current layout and can restore it on startup

LAYOUT_FILE="$HOME/.config/hypr/.keyboard_layout"
KEYBOARD_DEVICE="at-translated-set-2-keyboard"

case "$1" in
    save)
        # Get current layout index (0 or 1)
        CURRENT_LAYOUT=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$KEYBOARD_DEVICE\") | .active_keymap")
        
        # Save to file
        echo "$CURRENT_LAYOUT" > "$LAYOUT_FILE"
        ;;
    
    restore)
        # Check if layout file exists
        if [ -f "$LAYOUT_FILE" ]; then
            SAVED_LAYOUT=$(cat "$LAYOUT_FILE")
            CURRENT_LAYOUT=$(hyprctl devices -j | jq -r ".keyboards[] | select(.name == \"$KEYBOARD_DEVICE\") | .active_keymap")
            
            # Only switch if saved layout is different from current
            if [ "$SAVED_LAYOUT" != "$CURRENT_LAYOUT" ]; then
                # Switch to saved layout
                if [ "$SAVED_LAYOUT" == "Portuguese (Brazil)" ]; then
                    hyprctl switchxkblayout "$KEYBOARD_DEVICE" 1
                else
                    hyprctl switchxkblayout "$KEYBOARD_DEVICE" 0
                fi
            fi
        fi
        ;;
    
    switch)
        # Switch keyboard layout for ALL keyboards
        for kbd in $(hyprctl devices -j | jq -r '.keyboards[].name'); do
            hyprctl switchxkblayout "$kbd" next
        done
        
        # Save the new layout
        sleep 0.1  # Small delay to ensure layout has switched
        $0 save
        ;;
    
    *)
        echo "Usage: $0 {save|restore|switch}"
        exit 1
        ;;
esac
