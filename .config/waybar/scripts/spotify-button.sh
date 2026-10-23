#!/usr/bin/env bash
# spotify-button.sh toggle|next -> waybar JSON stream (follows playerctl)
# Prints empty text (module hidden) while Spotify isn't running.
mode=${1:-toggle}
ic_play=$(printf '\U000f040a'); ic_pause=$(printf '\U000f03e4'); ic_next=$(printf '\U000f04ad')

playerctl -p spotify -F status 2>/dev/null | while read -r status; do
    if [ -z "$status" ]; then
        echo '{"text":""}'
    elif [ "$mode" = next ]; then
        printf '{"text":"%s","tooltip":"Next track"}\n' "$ic_next"
    elif [ "$status" = Playing ]; then
        printf '{"text":"%s","class":"playing","tooltip":"Pause"}\n' "$ic_pause"
    else
        printf '{"text":"%s","class":"paused","tooltip":"Play"}\n' "$ic_play"
    fi
done
