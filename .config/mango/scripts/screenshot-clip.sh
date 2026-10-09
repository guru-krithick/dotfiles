#!/bin/sh
set -eu

region=$(slurp) || exit 0
[ -n "$region" ] || exit 0
capture=$(mktemp --suffix=.png)
trap 'rm -f "$capture"' EXIT HUP INT TERM
grim -g "$region" "$capture"
wl-copy --type image/png < "$capture"
