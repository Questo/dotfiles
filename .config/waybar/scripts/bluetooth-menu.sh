#!/usr/bin/env bash
# Bluetooth picker via wofi + bluetoothctl
set -uo pipefail

menu() { wofi --dmenu --insensitive --cache-file /dev/null --width 420 --height "${2:-360}" --prompt "$1"; }
notify() { notify-send -a Bluetooth -t 3000 "$(printf '\U000f00af')  Bluetooth" "$1" 2>/dev/null || true; }

ic_on=$(printf '\U000f00af'); ic_off=$(printf '\U000f00b2')
ic_conn=$(printf '\U000f00b1'); ic_dev=$(printf '\U000f00af')
ic_head=$(printf '\U000f02cb'); ic_kbd=$(printf '\U000f030c'); ic_mouse=$(printf '\U000f037d')
ic_scan=$(printf '\U000f0450')

power_on() {
    rfkill unblock bluetooth
    for _ in 1 2 3 4 5; do bluetoothctl power on >/dev/null 2>&1 && return 0; sleep 0.5; done
    notify "Could not power on"; return 1
}

device_icon() {
    case "$(bluetoothctl info "$1" | awk -F': ' '/Icon:/{print $2}')" in
        audio-head*|audio-card) echo "$ic_head" ;;
        input-keyboard) echo "$ic_kbd" ;;
        input-mouse)    echo "$ic_mouse" ;;
        *)              echo "$ic_dev" ;;
    esac
}

if ! bluetoothctl show | grep -q 'Powered: yes'; then
    choice=$(printf '%s\n' "$ic_on  Turn bluetooth on" | menu "Bluetooth is off" 120)
    [ -n "$choice" ] && power_on && exec "$0"
    exit 0
fi

# --- Scan for and pair a new device ---
if [ "${1:-}" = "--scan" ]; then
    notify "Scanning for 8 seconds..."
    bluetoothctl --timeout 8 scan on >/dev/null 2>&1
    declare -A mac_of; lines=()
    while read -r _ mac name; do
        bluetoothctl info "$mac" | grep -q 'Paired: yes' && continue
        [ -z "$name" ] || [[ "$name" == "${mac//:/-}" ]] && continue   # skip nameless
        line="$(device_icon "$mac")  $name"
        mac_of[$line]=$mac; lines+=("$line")
    done < <(bluetoothctl devices)
    [ ${#lines[@]} -eq 0 ] && { notify "No new devices found"; exit 0; }
    choice=$(printf '%s\n' "${lines[@]}" | menu "Pair device")
    mac=${mac_of[$choice]:-}; [ -z "$mac" ] && exit 0
    notify "Pairing ${choice#*  }..."
    if bluetoothctl --timeout 20 pair "$mac" >/dev/null 2>&1 \
        && bluetoothctl trust "$mac" >/dev/null 2>&1 \
        && bluetoothctl --timeout 15 connect "$mac" >/dev/null 2>&1; then
        notify "Connected to ${choice#*  }"
    else
        notify "Pairing failed (devices needing a PIN: use bluetoothctl)"
    fi
    exit 0
fi

# --- Main menu: paired devices ---
declare -A mac_of; declare -A seen_name; lines=()
paired=$(bluetoothctl devices Paired)
# count names to disambiguate duplicates
while read -r _ mac name; do seen_name[$name]=$(( ${seen_name[$name]:-0} + 1 )); done <<< "$paired"
while read -r _ mac name; do
    [ -z "$mac" ] && continue
    info=$(bluetoothctl info "$mac")
    label=$name; (( ${seen_name[$name]} > 1 )) && label="$name (${mac: -8})"
    if grep -q 'Connected: yes' <<< "$info"; then
        bat=$(awk -F'[()]' '/Battery Percentage/{print "  " $2 "%"}' <<< "$info")
        line="$ic_conn  $label$bat  (connected)"
    else
        line="$(device_icon "$mac")  $label"
    fi
    mac_of[$line]=$mac; lines+=("$line")
done <<< "$paired"

act_scan="$ic_scan  Pair new device..."
act_off="$ic_off  Turn bluetooth off"

choice=$(printf '%s\n' "${lines[@]}" "$act_scan" "$act_off" | menu "Bluetooth")
[ -z "$choice" ] && exit 0

case "$choice" in
    "$act_scan") exec "$0" --scan ;;
    "$act_off")  bluetoothctl power off >/dev/null; exit 0 ;;
esac

mac=${mac_of[$choice]:-}; [ -z "$mac" ] && exit 0
name=${choice#*  }; name=${name%  (connected)}
if [[ "$choice" == *"(connected)" ]]; then
    bluetoothctl disconnect "$mac" >/dev/null 2>&1 && notify "Disconnected $name"
else
    notify "Connecting to $name..."
    if bluetoothctl --timeout 15 connect "$mac" >/dev/null 2>&1; then
        notify "Connected to $name"
    else
        notify "Could not connect to $name"
    fi
fi
