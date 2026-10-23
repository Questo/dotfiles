#!/usr/bin/env bash
# Waybar custom/vpn: JSON status of NetworkManager VPN / WireGuard connections
ic_on=$(printf '\U000f0582'); ic_off=$(printf '\U000f099d')
active=$(nmcli -t -f NAME,TYPE con show --active | awk -F: '$2=="vpn"||$2=="wireguard"{print $1}')
if [ -n "$active" ]; then
    names=$(paste -sd', ' <<< "$active")
    short=$(sed 's/ VPN$//' <<< "$active" | paste -sd', ')
    printf '{"text":"%s  %s","class":"connected","tooltip":"VPN connected: %s\\nClick: VPN menu"}\n' "$ic_on" "$short" "$names"
else
    printf '{"text":"%s","class":"disconnected","tooltip":"VPN off\\nClick: VPN menu"}\n' "$ic_off"
fi
