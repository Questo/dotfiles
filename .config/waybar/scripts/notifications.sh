#!/usr/bin/env bash
# Waybar custom/notifications: unread count + do-not-disturb state for mako.
# Unread = active + history notifications newer than the last "seen" id.
# Usage: notifications.sh [status|menu|dnd|clear]
seen_file="${XDG_RUNTIME_DIR:-/tmp}/waybar-notif-seen"
ignore='["OSD","Idle"]'   # internal popups that shouldn't count

all() {
    { makoctl list -j; makoctl history -j; } |
        jq -s --argjson ig "$ignore" 'add | map(select(.app_name as $a | $ig | index($a) | not)) | unique_by(.id) | sort_by(-.id)'
}
mark_seen() { all | jq '.[0].id // 0' > "$seen_file"; pkill -RTMIN+9 waybar; }

case "${1:-status}" in
menu)
    mark_seen
    list=$(all | jq -r '.[] | "\(.app_name // "?"): \(.summary)\(if .body then " — " + (.body | gsub("\n"; " ")) else "" end)"')
    [ -n "$list" ] || list="No notifications"
    wofi --dmenu --prompt "Notifications" --width 600 --lines 12 <<< "$list" >/dev/null
    exit ;;
dnd)   makoctl mode -t do-not-disturb >/dev/null; pkill -RTMIN+9 waybar; exit ;;
clear) makoctl dismiss --all; mark_seen; exit ;;
esac

seen=$(cat "$seen_file" 2>/dev/null || echo 0)
# ids restart from 1 when mako restarts: then everything is new again
count=$(all | jq --argjson s "$seen" '(if (.[0].id // 0) < $s then 0 else $s end) as $s | map(select(.id > $s)) | length')
if makoctl mode | grep -qx do-not-disturb; then
    icon=$(printf '\U000f009b'); class=dnd; state="Do not disturb ON"
elif [ "$count" -gt 0 ]; then
    icon=$(printf '\U000f116b'); class=unread; state="$count unread"
else
    icon=$(printf '\U000f009a'); class=none; state="No new notifications"
fi
text=$icon; [ "$count" -gt 0 ] && text="$icon $count"
printf '{"text":"%s","class":"%s","tooltip":"%s\\nLeft: history · Middle: dismiss all · Right: toggle DND"}\n' "$text" "$class" "$state"
