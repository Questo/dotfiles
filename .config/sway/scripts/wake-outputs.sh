#!/usr/bin/env bash
# Force every output back on after idle/lid/dock changes. Used by swayidle's
# resume, lid open and the --locked emergency key ($mod+Ctrl+Escape).
#   wake-outputs.sh        power everything on, re-apply lid state
#   wake-outputs.sh hard   also disable/enable externals to force a relink
#                          (USB-C monitors that stay asleep after DPMS off)

log() { logger -t sway-wake "$*"; }
log "wake ($1) outputs: $(swaymsg -t get_outputs | jq -c '[.[] | {name, active, power}]')"

swaymsg 'output * power on' >/dev/null

if [ "$1" = hard ]; then
    for o in $(swaymsg -t get_outputs | jq -r '.[] | select(.name != "eDP-1" and .active) | .name'); do
        swaymsg output "$o" disable >/dev/null
        sleep 1
        swaymsg output "$o" enable >/dev/null
    done
fi

# Lid open -> internal panel on; closed + docked -> off (lid.sh sync)
if grep -q open /proc/acpi/button/lid/LID0/state; then
    swaymsg output eDP-1 enable >/dev/null
else
    ~/.config/sway/scripts/lid.sh sync
fi
log "after: $(swaymsg -t get_outputs | jq -c '[.[] | {name, active, power}]')"
