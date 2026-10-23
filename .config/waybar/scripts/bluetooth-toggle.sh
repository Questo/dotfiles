#!/usr/bin/env bash
# Toggle bluetooth power (unblocks rfkill when turning on)
if bluetoothctl show | grep -q 'Powered: yes'; then
    bluetoothctl power off
else
    rfkill unblock bluetooth
    for _ in 1 2 3 4 5; do bluetoothctl power on && exit 0; sleep 0.5; done
fi
