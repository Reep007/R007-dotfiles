#!/bin/bash

options="Configure Printers\nList Printers\nList Print Jobs"

selected=$(echo -e "$options" | wofi --show dmenu --prompt "Printer Settings")

case "$selected" in
    "Configure Printers") GDK_BACKEND=x11 system-config-printer ;;
    "List Printers") lpstat -p | wofi --show dmenu --prompt "Available Printers" ;;
    "List Print Jobs") lpq | wofi --show dmenu --prompt "Print Jobs" ;;
esac
