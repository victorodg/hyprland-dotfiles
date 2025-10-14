#!/bin/bash

# Hyprland Workspace Manager Script
# Provides intelligent workspace navigation and window management

get_active_workspace() {
    hyprctl activeworkspace -j | jq '.id'
}

get_existing_workspaces() {
    hyprctl workspaces -j | jq '[.[] | .id] | sort'
}

get_windows_on_workspace() {
    local workspace_id=$1
    hyprctl clients -j | jq "[.[] | select(.workspace.id == $workspace_id)] | length"
}

switch_to_workspace() {
    local workspace_id=$1
    hyprctl dispatch workspace "$workspace_id"
}

move_to_workspace() {
    local workspace_id=$1
    hyprctl dispatch movetoworkspace "$workspace_id"
}

get_next_existing_workspace() {
    local current_workspace=$1
    local workspaces=($(hyprctl workspaces -j | jq -r '[.[] | .id] | sort | .[]'))
    
    for i in "${!workspaces[@]}"; do
        if [[ "${workspaces[$i]}" == "$current_workspace" ]]; then
            local next_index=$(( (i + 1) % ${#workspaces[@]} ))
            echo "${workspaces[$next_index]}"
            return
        fi
    done
    
    # If current workspace not found, return first workspace
    echo "${workspaces[0]}"
}

get_previous_existing_workspace() {
    local current_workspace=$1
    local workspaces=($(hyprctl workspaces -j | jq -r '[.[] | .id] | sort | .[]'))
    
    for i in "${!workspaces[@]}"; do
        if [[ "${workspaces[$i]}" == "$current_workspace" ]]; then
            local prev_index=$(( (i - 1 + ${#workspaces[@]}) % ${#workspaces[@]} ))
            echo "${workspaces[$prev_index]}"
            return
        fi
    done
    
    # If current workspace not found, return last workspace
    echo "${workspaces[-1]}"
}

get_next_workspace_for_move() {
    local current_workspace=$1
    local next_workspace=$((current_workspace + 1))
    
    # If next workspace would exceed 10, wrap to 1
    if [[ $next_workspace -gt 10 ]]; then
        next_workspace=1
    fi
    
    echo "$next_workspace"
}

get_previous_workspace_for_move() {
    local current_workspace=$1
    local prev_workspace=$((current_workspace - 1))
    
    # If previous workspace would be less than 1, wrap to 10
    if [[ $prev_workspace -lt 1 ]]; then
        prev_workspace=10
    fi
    
    echo "$prev_workspace"
}

renumber_workspaces() {
    local workspaces=($(hyprctl workspaces -j | jq -r '[.[] | select(.id > 0) | .id] | sort | .[]'))
    local target_number=1
    
    for workspace_id in "${workspaces[@]}"; do
        if [[ $workspace_id -ne $target_number ]]; then
            # Move all windows from current workspace to target number
            local windows=($(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace_id) | .address"))
            
            for window in "${windows[@]}"; do
                hyprctl dispatch movetoworkspacesilent "$target_number,address:$window"
            done
            
            # Small delay to ensure moves complete
            sleep 0.1
        fi
        ((target_number++))
    done
}

case "$1" in
    "left")
        current_workspace=$(get_active_workspace)
        previous_workspace=$(get_previous_existing_workspace "$current_workspace")
        
        if [[ "$previous_workspace" != "$current_workspace" ]]; then
            switch_to_workspace "$previous_workspace"
        fi
        ;;
        
    "right")
        current_workspace=$(get_active_workspace)
        workspaces=($(hyprctl workspaces -j | jq -r '[.[] | .id] | sort | .[]'))
        
        # Check if current workspace is the last existing workspace
        last_workspace=${workspaces[-1]}
        
        if [[ "$current_workspace" == "$last_workspace" ]]; then
            # We're at the last workspace, check if it has windows
            current_window_count=$(get_windows_on_workspace "$current_workspace")
            
            if [[ $current_window_count -gt 0 ]]; then
                # Current workspace has windows, create a new one
                new_workspace=$((last_workspace + 1))
                # Ensure we don't exceed workspace 10
                if [[ $new_workspace -le 10 ]]; then
                    switch_to_workspace "$new_workspace"
                fi
            else
                # Current workspace is empty, go back to workspace 1 (circular navigation)
                switch_to_workspace 1
            fi
        else
            # Normal behavior - go to next existing workspace
            next_workspace=$(get_next_existing_workspace "$current_workspace")
            if [[ "$next_workspace" != "$current_workspace" ]]; then
                switch_to_workspace "$next_workspace"
            fi
        fi
        ;;
        
    "move-left")
        current_workspace=$(get_active_workspace)
        target_workspace=$(get_previous_workspace_for_move "$current_workspace")
        
        move_to_workspace "$target_workspace"
        
        # If the original workspace is now empty and not workspace 1, clean up
        window_count=$(get_windows_on_workspace "$current_workspace")
        if [[ $window_count -eq 0 && $current_workspace -ne 1 ]]; then
            sleep 0.2  # Brief delay to ensure move completes
            renumber_workspaces
        fi
        ;;
        
    "move-right")
        current_workspace=$(get_active_workspace)
        target_workspace=$(get_next_workspace_for_move "$current_workspace")
        
        move_to_workspace "$target_workspace"
        
        # If the original workspace is now empty and not workspace 1, clean up
        window_count=$(get_windows_on_workspace "$current_workspace")
        if [[ $window_count -eq 0 && $current_workspace -ne 1 ]]; then
            sleep 0.2  # Brief delay to ensure move completes
            renumber_workspaces
        fi
        ;;
        
    "check-renumber")
        # Check if current workspace is empty after killing a window
        current_workspace=$(get_active_workspace)
        window_count=$(get_windows_on_workspace "$current_workspace")
        
        if [[ $window_count -eq 0 && $current_workspace -ne 1 ]]; then
            # Switch to workspace 1 before renumbering if we're on an empty workspace
            switch_to_workspace 1
            sleep 0.1
            renumber_workspaces
        fi
        ;;
        
    "status")
        # Display current workspace information (useful for debugging)
        current_workspace=$(get_active_workspace)
        existing_workspaces=$(get_existing_workspaces)
        
        echo "Current workspace: $current_workspace"
        echo "Existing workspaces: $existing_workspaces"
        ;;
        
    *)
        echo "Usage: $0 {left|right|move-left|move-right|check-renumber|status}"
        echo ""
        echo "  left        - Switch to previous existing workspace"
        echo "  right       - Switch to next existing workspace"
        echo "  move-left   - Move active window to previous workspace (1-10, wrapping)"
        echo "  move-right  - Move active window to next workspace (1-10, wrapping)"
        echo "  check-renumber - Check and renumber workspaces after window closure"
        echo "  status      - Display current workspace information"
        exit 1
        ;;
esac
