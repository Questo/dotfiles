#!/usr/bin/env bash
# osd.sh <key> <icon> <title> <value>  -> mako popup with a level bar, replaced in place
idfile="${XDG_RUNTIME_DIR:-/tmp}/osd-$1.id"
id=$(cat "$idfile" 2>/dev/null || echo 0)
notify-send -a OSD -t 1500 -u low -p -r "$id" -h "int:value:$4" "$2  $3" "$4%" > "$idfile" 2>/dev/null
