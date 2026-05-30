#!/bin/sh
VIDS="${XDG_VIDEOS_DIR:-$HOME/Recordings}"
wf-recorder -g "$(slurp)" -f "$VIDS/recording-$(date +%Y%m%d-%H%M%S).mp4"
