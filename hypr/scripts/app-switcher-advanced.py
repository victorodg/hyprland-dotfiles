#!/usr/bin/env python3

import json
import subprocess
import sys
from pynput import keyboard
from pynput.keyboard import Key, Controller

# State
current_index = 0
windows = []
is_running = True
kbd = Controller()

def get_windows():
    """Get all windows across all workspaces"""
    result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True)
    clients = json.loads(result.stdout)
    
    window_list = []
    for client in clients:
        window_list.append({
            'workspace': client['workspace']['id'],
            'address': client['address'],
            'class': client['class'],
            'title': client['title'][:60]  # Truncate long titles
        })
    
    return window_list

def switch_to_window(window):
    """Switch to the selected window"""
    subprocess.run(['hyprctl', 'dispatch', 'workspace', str(window['workspace'])])
    subprocess.run(['hyprctl', 'dispatch', 'focuswindow', f"address:{window['address']}"])

def show_notification(window, index, total):
    """Show current selection"""
    msg = f"[{index + 1}/{total}] [WS {window['workspace']}] {window['class']} - {window['title']}"
    subprocess.run(['notify-send', '-t', '1000', '-u', 'low', 'App Switcher', msg])

def on_release(key):
    """Handle key releases"""
    global is_running
    
    # When Super is released, confirm selection
    if key in [Key.cmd, Key.cmd_l, Key.cmd_r]:
        is_running = False
        return False

def cycle_next():
    """Cycle to next window"""
    global current_index
    current_index = (current_index + 1) % len(windows)
    show_notification(windows[current_index], current_index, len(windows))

def main():
    global windows, current_index
    
    # Get all windows
    windows = get_windows()
    
    if not windows:
        subprocess.run(['notify-send', 'App Switcher', 'No windows found'])
        sys.exit(0)
    
    if len(windows) == 1:
        # Only one window, just switch to it
        switch_to_window(windows[0])
        sys.exit(0)
    
    # Start at index 1 (next window)
    current_index = 1
    show_notification(windows[current_index], current_index, len(windows))
    
    # Set up keyboard listener
    listener = keyboard.Listener(on_release=on_release)
    listener.start()
    
    # Wait for Tab presses or Super release
    print("Press Tab to cycle, release Super to select")
    
    listener.join()
    
    # Switch to selected window
    switch_to_window(windows[current_index])

if __name__ == '__main__':
    main()
