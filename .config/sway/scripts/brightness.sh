#!/usr/bin/env bash
# brightness.sh up|down  (via systemd-logind, no root or brightnessctl needed)
dev=intel_backlight
cur=$(cat /sys/class/backlight/$dev/brightness)
max=$(cat /sys/class/backlight/$dev/max_brightness)
step=$(( max * 5 / 100 ))
case "$1" in
    up)   new=$(( cur + step )) ;;
    down) new=$(( cur - step )) ;;
    *)    exit 1 ;;
esac
(( new > max )) && new=$max
(( new < max / 100 )) && new=$(( max / 100 ))   # never fully black
busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
    org.freedesktop.login1.Session SetBrightness ssu backlight $dev $new
~/.config/sway/scripts/osd.sh bright "$(printf '\U000f00e0')" "Brightness" $(( (new * 100 + max / 2) / max ))
