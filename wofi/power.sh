#!/bin/bash

entries="⏻ Shutdown\n⭮ Reboot\n⏾ Suspend\n⇠ Logout"

selected=$(echo -e $entries | wofi --dmenu --cache-file=/dev/null --style ~/.config/wofi/power.css --width=250 --height=220 --prompt="Power Menu")

case $selected in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "⭮ Reboot")
        systemctl reboot
        ;;
    "⏾ Suspend")
        systemctl suspend
        ;;
    "⇠ Logout")
        hyprctl dispatch exit
        ;;
esac