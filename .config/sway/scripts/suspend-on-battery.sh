#!/usr/bin/env bash
# Called by swayidle after long idle: suspend only when running on battery.
[ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = 0 ] && exec systemctl suspend
exit 0
