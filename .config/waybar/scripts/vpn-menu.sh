#!/usr/bin/env bash
# Toggle NetworkManager VPN / WireGuard connections via wofi
set -uo pipefail

ic_on=$(printf '\U000f0582'); ic_off=$(printf '\U000f099d'); ic_edit=$(printf '\U000f0493')
notify() { notify-send -a VPN -t 3000 "$ic_on  VPN" "$1" 2>/dev/null || true; }
refresh() { pkill -RTMIN+8 waybar 2>/dev/null || true; }

declare -A uuid_of; lines=()
active=$(nmcli -t -f UUID con show --active)
while IFS=: read -r name uuid type; do
    [[ "$type" == "vpn" || "$type" == "wireguard" ]] || continue
    if grep -qx "$uuid" <<< "$active"; then line="$ic_on  $name  (connected)"; else line="$ic_off  $name"; fi
    uuid_of[$line]=$uuid; lines+=("$line")
done < <(nmcli -t -f NAME,UUID,TYPE con show)

act_edit="$ic_edit  Edit connections..."
choice=$(printf '%s\n' "${lines[@]}" "$act_edit" \
    | wofi --dmenu --insensitive --cache-file /dev/null --width 420 --height 220 --prompt "VPN")
[ -z "$choice" ] && exit 0
[ "$choice" = "$act_edit" ] && exec nm-connection-editor

uuid=${uuid_of[$choice]:-}; [ -z "$uuid" ] && exit 0
name=${choice#*  }; name=${name%  (connected)}

if [[ "$choice" == *"(connected)" ]]; then
    nmcli con down uuid "$uuid" >/dev/null 2>&1 && notify "Disconnected from $name"
    refresh; exit 0
fi

notify "Connecting to $name..."
# OpenVPN with an agent-owned password (password-flags=1): NetworkManager can't
# ask for it under sway (no GNOME agent), so take it from the keyring or ask.
if [ "$(nmcli -g connection.type con show uuid "$uuid")" = "vpn" ] \
    && nmcli -g vpn.data con show uuid "$uuid" | grep -q 'password-flags = 1'; then
    pw=$(secret-tool lookup connection-uuid "$uuid" setting-name vpn setting-key password 2>/dev/null || true)
    if [ -z "$pw" ]; then
        pw=$(wofi --dmenu --password --cache-file /dev/null --width 420 --height 60 --prompt "Password for $name")
        [ -z "$pw" ] && { refresh; exit 0; }
    fi
    out=$(nmcli con up uuid "$uuid" passwd-file <(printf 'vpn.secrets.password:%s\n' "$pw") 2>&1); rc=$?
    unset pw
else
    out=$(nmcli con up uuid "$uuid" 2>&1); rc=$?
fi

if [ $rc -eq 0 ]; then notify "Connected to $name"; else notify "Failed: ${out##*Error: }"; fi
refresh
