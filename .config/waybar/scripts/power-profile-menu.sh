#!/usr/bin/env bash
# Pick a power profile via wofi (works with power-profiles-daemon or tuned-ppd)
set -euo pipefail

BUS=(net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles)

current=$(busctl get-property "${BUS[@]}" ActiveProfile | awk -F'"' '{print $2}')

choice=$(printf '%s\n' performance balanced power-saver \
    | sed "s/^$current\$/$current  (active)/" \
    | wofi --dmenu --prompt "Power profile" --width 300 --height 180 --cache-file /dev/null \
    | awk '{print $1}')

[ -n "$choice" ] || exit 0
busctl set-property "${BUS[@]}" ActiveProfile s "$choice"
notify-send -a Power -t 2000 "Power profile" "Switched to $choice" 2>/dev/null || true
