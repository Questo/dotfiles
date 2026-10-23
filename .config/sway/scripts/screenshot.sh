#!/usr/bin/env bash
# screenshot.sh area|full  -> saves to ~/downloads/screenshots and copies to clipboard
# area: drag to select a region, or click a window to capture it
dir="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$HOME/downloads")/screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-area}" in
    area)
        windows=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')
        geom=$(slurp -d -b '#1e1e2e66' -c '#89b4faff' -s '#89b4fa22' -w 2 <<< "$windows") || exit 0
        sleep 0.1   # let slurp's overlay disappear
        grim -g "$geom" "$file" ;;
    full)
        out=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused) | .name')
        grim -o "$out" "$file" ;;
    *) echo "usage: $0 area|full" >&2; exit 1 ;;
esac || { notify-send -a Screenshot -u critical "Screenshot failed"; exit 1; }

wl-copy --type image/png < "$file"
notify-send -a Screenshot -t 4000 -i "$file" "$(printf '\U000f0104')  Screenshot saved" "Copied to clipboard\n${file/#$HOME/\~}"
