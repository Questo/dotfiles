#!/usr/bin/env bash
# Wifi picker via wofi + nmcli
set -uo pipefail

menu() { wofi --dmenu --insensitive --cache-file /dev/null --width 420 --height 400 --prompt "$1"; }

# Nerd Font icons (generated at runtime to keep this file ASCII)
ic_sig=( "$(printf '\U000f092f')" "$(printf '\U000f091f')" "$(printf '\U000f0922')" "$(printf '\U000f0925')" "$(printf '\U000f0928')" )
ic_lock=$(printf '\U000f033e')
ic_on=$(printf '\U000f05a9'); ic_off=$(printf '\U000f05aa')
ic_scan=$(printf '\U000f0450'); ic_edit=$(printf '\U000f0493')

if [ "$(nmcli radio wifi)" != "enabled" ]; then
    choice=$(printf '%s\n' "$ic_on  Turn wifi on" | menu "Wifi is off")
    [ -n "$choice" ] && nmcli radio wifi on
    exit 0
fi

declare -A ssid_of
lines=()
declare -A seen
# IN-USE:SIGNAL:SECURITY:SSID  (SSID last, so colons in it are safe with -e no)
while IFS=: read -r inuse signal security ssid; do
    [ -z "$ssid" ] && continue
    [ -n "${seen[$ssid]:-}" ] && continue
    seen[$ssid]=1
    idx=$(( signal / 21 )); (( idx > 4 )) && idx=4
    lock=""; [ -n "$security" ] && [ "$security" != "--" ] && lock="  $ic_lock"
    mark=""; [ "$inuse" = "*" ] && mark="  (connected)"
    line="${ic_sig[$idx]}  $ssid$lock$mark"
    ssid_of[$line]=$ssid
    lines+=("$line")
done < <(nmcli -t -e no -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan auto)

act_scan="$ic_scan  Rescan"
act_edit="$ic_edit  Edit connections..."
act_off="$ic_off  Turn wifi off"

choice=$(printf '%s\n' "${lines[@]}" "$act_scan" "$act_edit" "$act_off" | menu "Wifi")
[ -z "$choice" ] && exit 0

case "$choice" in
    "$act_scan") nmcli dev wifi rescan; sleep 2; exec "$0" ;;
    "$act_edit") exec nm-connection-editor ;;
    "$act_off")  exec nmcli radio wifi off ;;
esac

ssid=${ssid_of[$choice]:-}
[ -z "$ssid" ] && exit 0
[[ "$choice" == *"(connected)" ]] && exit 0

# Known network -> just bring it up
if nmcli -t -f NAME,TYPE con show | grep -Fxq "$ssid:802-11-wireless"; then
    nmcli con up id "$ssid" >/dev/null 2>&1 && exit 0
fi

if [[ "$choice" == *"$ic_lock"* ]]; then
    pass=$(wofi --dmenu --password --cache-file /dev/null --width 420 --height 60 --prompt "Password for $ssid")
    [ -z "$pass" ] && exit 0
    nmcli dev wifi connect "$ssid" password "$pass" >/dev/null 2>&1
else
    nmcli dev wifi connect "$ssid" >/dev/null 2>&1
fi
