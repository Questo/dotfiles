#!/usr/bin/env bash
# volume.sh up|down|mute|micmute
osd=~/.config/sway/scripts/osd.sh
case "$1" in
    up)      wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down)    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute)    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    micmute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            "$osd" mic "$(printf '\U000f036d')" "Mic muted" 0
        else
            "$osd" mic "$(printf '\U000f036c')" "Mic on" 100
        fi
        exit 0 ;;
esac
out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
vol=$(awk '{printf "%d", $2*100 + 0.5}' <<< "$out")
if [[ "$out" == *MUTED* ]]; then
    "$osd" vol "$(printf '\U000f075f')" "Muted" "$vol"
else
    "$osd" vol "$(printf '\U000f057e')" "Volume" "$vol"
fi
