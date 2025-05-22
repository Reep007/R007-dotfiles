#!/bin/zsh
# ~/.config/waybar/scripts/network-status.sh

LOGFILE="$HOME/.cache/network_status.log"
echo "$(date): Starting network-status.sh" >> "$LOGFILE"

# Check Ethernet
eth_interface=$(nmcli -t -f DEVICE,TYPE device | grep ethernet | cut -d: -f1)
if [[ -n "$eth_interface" ]]; then
    eth_status=$(nmcli -t -f GENERAL.STATE device show "$eth_interface" | cut -d: -f2)
    eth_ip=$(nmcli -t -f IP4.ADDRESS device show "$eth_interface" | cut -d: -f2 | head -n1)
    eth_conn=$(nmcli -t -f GENERAL.CONNECTION device show "$eth_interface" | cut -d: -f2)
    if [[ "$eth_status" =~ "connected" && -n "$eth_conn" ]]; then
        output="{\"text\": \"󰒒 󰩃  \", \"class\": \"connected\"}"
        echo "$output" >> "$LOGFILE"
        echo "$output"
        exit 0
    fi
fi

# No connection
output="{\"text\": \"󰌙 No Network\", \"class\": \"disconnected\"}"
echo "$output" >> "$LOGFILE"
echo "$output"

