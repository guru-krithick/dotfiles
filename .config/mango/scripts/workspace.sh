#!/bin/sh
# Global number shortcuts over Mango's per-monitor tags; supports undocking.
set -eu

case "${1-}:${2-}" in
    view:[1-9]|tag:[1-9]) ;;
    *) echo "Usage: $0 view|tag 1-9" >&2; exit 2 ;;
esac

action=$1
tag=$2
if [ "$tag" -le 5 ]; then
    preferred=HDMI-A-1
else
    preferred=eDP-1
fi

# 'active' means focused in Mango IPC, not connected/enabled.
# all-monitors enumerates the available outputs; prefer the focused fallback.
monitor=$(mmsg get all-monitors | jq -er --arg preferred "$preferred" '
    .monitors | (map(select(.name == $preferred))[0]
        // map(select(.active))[0] // .[0]) | .name
')
exec mmsg dispatch "${action}crossmon,$tag,$monitor"
