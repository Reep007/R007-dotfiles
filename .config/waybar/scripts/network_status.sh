#!/bin/bash

# Get the first non-loopback IPv4 address
ip=$(hostname -I | awk '{print $1}')

# Output only an icon or label in Waybar, IP is only in tooltip
echo "{\"text\": \"🌐\", \"tooltip\": \"IP Address: $ip\"}"
