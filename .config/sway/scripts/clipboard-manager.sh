#!/bin/bash

# Enhanced clipboard manager with wofi and cliphist
# Handles text, images (including web images), and files
# Ensures only one instance runs at a time

# Lock file to prevent multiple instances
LOCK_FILE="/tmp/clipboard-manager.lock"

# Configuration files
WOFI_CONFIG="$HOME/.config/wofi/config"
WOFI_STYLE="$HOME/.config/wofi/style.css"

# Check if script is already running
if [ -f "$LOCK_FILE" ]; then
    # Check if process is actually running
    PID=$(cat "$LOCK_FILE")
    if ps -p "$PID" > /dev/null; then
        notify-send "Clipboard Manager" "Another instance is already running"
        exit 1
    else
        # Stale lock file, remove it
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file with current PID
echo $$ > "$LOCK_FILE"

# Cleanup function
cleanup() {
    rm -f "$LOCK_FILE"
    exit 0
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT INT TERM

# Function to show wofi menu with proper styling
show_wofi() {
    local prompt=$1
    wofi --dmenu --conf="$WOFI_CONFIG" --style="$WOFI_STYLE" --prompt="$prompt" --cache-file=/dev/null
}

# Function to handle URL images
handle_url_image() {
    local content="$1"
    local image_url=""
    
    # Check if content looks like an image URL
    if [[ "$content" =~ https?://.*\.(jpg|jpeg|png|gif|webp) ]]; then
        image_url=$(echo "$content" | grep -o 'https\?://[^"'"'"']*\.\(jpg\|jpeg\|png\|gif\|webp\)')
    elif [[ "$content" =~ https?://.*\?.*image ]]; then
        # Handle more complex image URLs like from Amazon
        image_url="$content"
    fi
    
    if [ -n "$image_url" ]; then
        # Download the image to a temporary file
        local tmp_file="/tmp/clipboard_image_$(date +%s).png"
        if curl -s "$image_url" -o "$tmp_file"; then
            # Check if it's actually an image
            if file --mime-type -b "$tmp_file" | grep -q "^image/"; then
                notify-send "Image URL detected" "Downloaded and copied to clipboard"
                wl-copy < "$tmp_file"
                return 0
            else
                rm -f "$tmp_file"
            fi
        fi
    fi
    return 1
}

case "$1" in
  "copy")
    # Copy to clipboard
    selected=$(cliphist list | show_wofi "Copy")
    if [ -n "$selected" ]; then
        content=$(echo "$selected" | cliphist decode)
        
        # Check if it might be an image URL
        if handle_url_image "$content"; then
            exit 0
        else
            # Regular copy operation
            echo "$content" | wl-copy
            notify-send "Copied to clipboard" "Content copied successfully"
        fi
    fi
    ;;
  "delete")
    # Delete from clipboard history
    selected=$(cliphist list | show_wofi "Delete")
    if [ -n "$selected" ]; then
        echo "$selected" | cliphist delete
        notify-send "Deleted from history" "Item removed from clipboard history"
    fi
    ;;
  *)
    # Default to copy
    selected=$(cliphist list | show_wofi "Clipboard History")
    if [ -n "$selected" ]; then
        content=$(echo "$selected" | cliphist decode)
        
        # Check if it might be an image URL
        if handle_url_image "$content"; then
            exit 0
        else
            # Regular copy operation
            echo "$content" | wl-copy
            notify-send "Copied to clipboard" "Content copied successfully"
        fi
    fi
    ;;
esac
