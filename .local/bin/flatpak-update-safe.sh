#!/usr/bin/env bash
# flatpak update that gives way to suspend. A flatpak task blocked in FUSE
# can't be frozen, which hangs the whole suspend (black, unresponsive screen).
# Holds a sleep delay lock; when logind announces sleep, kill the update and
# release the lock so the suspend goes through. The next timer run retries.

if [ -z "${FLATPAK_SAFE_INHIBITED:-}" ]; then
    export FLATPAK_SAFE_INHIBITED=1
    exec systemd-inhibit --what=sleep --mode=delay --who=flatpak-update \
        --why="Abort update before sleep" "$0" "$@"
fi

flatpak update --noninteractive && flatpak uninstall --unused --noninteractive &
work=$!
gdbus monitor --system --dest org.freedesktop.login1 --object-path /org/freedesktop/login1 \
    | grep -m1 -q "PrepareForSleep (true" &
watch=$!

wait -n -p done "$work" "$watch"
rc=$?
pkill -P $$ gdbus

if [ "$done" = "$watch" ]; then
    echo "Sleep requested: aborting flatpak update" >&2
    pkill -KILL -P "$work"
    kill -KILL "$work"
    exit 1
fi
exit "$rc"
