#!/usr/bin/env bash
# Lid handling owned by sway (logind's lid action is inhibited in the sway config).
#   close: external output active -> just disable eDP-1; otherwise suspend
#   open:  re-enable eDP-1
#   sync:  disable eDP-1 if the lid is closed and an external is active (kanshi exec)
#   watch: suspend when the last external disappears while the lid is closed
# Docked state is checked once, at the moment the lid closes, so a monitor that
# drops its connection in standby can never trigger a surprise suspend.

lid_closed() { grep -q closed /proc/acpi/button/lid/LID0/state; }

# none = no active external output, on = one is lit, off = all DPMS'd by swayidle
externals() {
    swaymsg -t get_outputs | jq -r '[.[] | select(.name != "eDP-1" and .active)]
        | if length == 0 then "none" elif any(.[]; .power) then "on" else "off" end'
}

case "$1" in
close)
    if [ "$(externals)" = none ]; then
        systemctl suspend
    else
        swaymsg output eDP-1 disable
    fi
    ;;
open)
    ~/.config/sway/scripts/wake-outputs.sh lid
    ;;
sync)
    lid_closed && [ "$(externals)" != none ] && swaymsg output eDP-1 disable
    ;;
watch)
    # Only an unplug of a lit monitor counts: a monitor that vanishes after
    # swayidle powered it off is just standby, swayidle's own timers cover that.
    prev=$(externals)
    swaymsg -m -t subscribe '["output"]' | while read -r _; do
        now=$(externals)
        if [ "$now" = none ] && [ "$prev" = on ] && lid_closed; then
            sleep 2 # debounce dock re-enumeration
            [ "$(externals)" = none ] && lid_closed && systemctl suspend
            now=$(externals)
        fi
        prev=$now
    done
    ;;
esac
