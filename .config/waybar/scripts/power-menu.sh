#!/usr/bin/env bash
# Session/power menu via wofi. Destructive actions ask for confirmation.
set -uo pipefail

menu() { wofi --dmenu --insensitive --cache-file /dev/null --width 300 --height "$2" --prompt "$1"; }

lock="$(printf '\U000f033e')  Lock"
sleep_="$(printf '\U000f04b2')  Suspend"
logout="$(printf '\U000f0343')  Log out"
reboot="$(printf '\U000f0709')  Restart"
poweroff="$(printf '\U000f0425')  Shut down"

confirm() {
    [ "$(printf '%s\n' "No" "Yes, ${1,,}" | menu "$1?" 130)" = "Yes, ${1,,}" ]
}

choice=$(printf '%s\n' "$lock" "$sleep_" "$logout" "$reboot" "$poweroff" | menu "Power" 260)
case "$choice" in
    "$lock")     swaylock -f ;;
    "$sleep_")   systemctl suspend ;;
    "$logout")   confirm "Log out"   && swaymsg exit ;;
    "$reboot")   confirm "Restart"   && systemctl reboot ;;
    "$poweroff") confirm "Shut down" && systemctl poweroff ;;
esac
