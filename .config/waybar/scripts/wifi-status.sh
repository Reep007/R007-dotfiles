#!/usr/bin/env bash

# This script gathers detailed Wi-Fi connection information.
# It collects the following fields:
#
# - SSID (Service Set Identifier): The name of the Wi-Fi network you
#   are currently connected to.  Example: "My_Network"
#
# - IP Address: The IP address assigned to the device by the router.
#   This is typically a private IP within the local network.  Example:
#   "192.168.1.29/24" (with subnet mask)
#
# - Router (Gateway): The IP address of the router (default gateway)
#   that your device uses to communicate outside the local network.
#   Example: "192.168.1.1"
#
# - MAC Address: The unique Media Access Control address of the local
#   device's Wi-Fi adapter.  Example: "F8:34:41:07:1B:65"
#
# - Security: The encryption protocol being used to secure your Wi-Fi
#   connection. Common security protocols include:
#   - WPA2 (Wi-Fi Protected Access 2): The most commonly used security
#     standard, offering strong encryption (AES).
#   - WPA3: The latest version, providing even stronger security,
#     especially in public or open networks.
#   - WEP (Wired Equivalent Privacy): An outdated and insecure protocol
#     that should not be used.
#   Example: "WPA2" indicates that the connection is secured using WPA2
#   with AES encryption.
#
# - BSSID (Basic Service Set Identifier): The MAC address of the Wi-Fi
#   access point you are connected to.  Example: "A4:22:49:DA:91:A0"
#
# - Channel: The wireless channel your Wi-Fi network is using. This is
#   associated with the frequency band.  Example: "100 (5500 MHz)"
#   indicates the channel number (100) and the frequency (5500 MHz),
#   which is within the 5 GHz band.
#
# - RSSI (Received Signal Strength Indicator): The strength of the
#   Wi-Fi signal, typically in dBm (decibels relative to 1 milliwatt).
#   Closer to 0 means stronger signal, with values like -40 dBm being
#   very good.  Example: "-40 dBm"
#
# - Signal: The signal quality, which is represented as a percentage,
#   where higher numbers mean better signal.  Example: "100"
#   indicates perfect signal strength.
#
# - Rx Rate (Receive Rate): The maximum data rate (in Mbit/s) at which
#   the device can receive data from the Wi-Fi access point.  Example:
#   "866.7 MBit/s" indicates a high-speed connection on a modern
#   standard.
#
# - Tx Rate (Transmit Rate): The maximum data rate (in Mbit/s) at
#   which the device can send data to the Wi-Fi access point.  Example:
#   "866.7 MBit/s"
#
# - PHY Mode (Physical Layer Mode): The Wi-Fi protocol or standard in
#   use.  Common modes include 802.11n, 802.11ac, and 802.11ax (Wi-Fi
#   6).  Example: "802.11ac" indicates you're using the 5 GHz band with
#   a modern high-speed standard.


#!/bin/bash

# Check if nmcli is available
if ! command -v nmcli &>/dev/null; then
  echo "{\"text\": \"󰤫\", \"tooltip\": \"nmcli utility is missing\"}"
  exit 1
fi

# Check if Wi-Fi is enabled
wifi_status=$(nmcli radio wifi)
if [ "$wifi_status" = "disabled" ]; then
  echo "{\"text\": \"󰤮\", \"tooltip\": \"Wi-Fi Disabled\"}"
  exit 0
fi

# Get active Wi-Fi info
wifi_info=$(nmcli -t -f active,ssid,signal,security dev wifi | grep "^yes")
if [ -z "$wifi_info" ]; then
  echo "{\"text\": \"󰤭\", \"tooltip\": \"No Connection\"}"
  exit 0
fi

# Extract info
ssid=$(echo "$wifi_info" | awk -F: '{print $2}')
signal=$(echo "$wifi_info" | awk -F: '{print $3}')
security=$(echo "$wifi_info" | awk -F: '{print $4}')

# Get device info
active_device=$(nmcli -t -f DEVICE,STATE device status | grep ':connected' | grep -v -E '^(lo|dummy)' | cut -d: -f1)

if [ -n "$active_device" ]; then
  ip_address=$(nmcli -g IP4.ADDRESS device show "$active_device" | head -n1 | cut -d/ -f1)
  chan_info=$(nmcli -t -f active,chan,freq dev wifi | grep "^yes" | cut -d: -f2-)
  channel=$(echo "$chan_info" | cut -d: -f1)
  freq=$(echo "$chan_info" | cut -d: -f2)
else
  ip_address="Unavailable"
  channel="?"
  freq="?"
fi

# Choose icon by signal strength
if ((signal >= 80)); then
  icon="󰤨"  # strong
elif ((signal >= 60)); then
  icon="󰤥"  # good
elif ((signal >= 40)); then
  icon="󰤢"  # fair
elif ((signal >= 20)); then
  icon="󰤟"  # weak
else
  icon="󰤯"  # very weak
fi

# Output JSON for Waybar (no IP in text)
# Output JSON for Waybar
echo -n '{'
echo -n "\"text\": \"$icon\","
echo -n "\"tooltip\": \"SSID: $ssid\\nSignal: $signal/100\\nChannel: $channel ($freq MHz)\\nSecurity: $security\\nIP Address: $ip_address\","
echo -n "\"class\": \"connected\""
echo '}'
