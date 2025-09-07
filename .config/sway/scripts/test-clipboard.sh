#!/bin/bash

# Script to test different clipboard content types

# Function to show menu
show_test_menu() {
  echo -e "1. Copy text\n2. Copy image URL\n3. Copy Amazon image URL\n4. Clear clipboard\n5. Exit" | \
  wofi --dmenu --prompt="Select test" --conf=/home/guru/.config/wofi/config --style=/home/guru/.config/wofi/style.css
}

# Main loop
while true; do
  choice=$(show_test_menu)
  
  case $choice in
    "1. Copy text")
      echo "This is a test text for the clipboard manager" | wl-copy
      notify-send "Test" "Text copied to clipboard"
      ;;
    "2. Copy image URL")
      echo "https://example.com/test.jpg" | wl-copy
      notify-send "Test" "Image URL copied to clipboard"
      ;;
    "3. Copy Amazon image URL")
      echo "https://m.media-amazon.com/images/I/61Dm+yj-CRL._UXNaN_FMjpg_QL85_.jpg" | wl-copy
      notify-send "Test" "Amazon image URL copied to clipboard"
      ;;
    "4. Clear clipboard")
      wl-copy --clear
      notify-send "Test" "Clipboard cleared"
      ;;
    "5. Exit")
      break
      ;;
    *)
      notify-send "Invalid choice" "Please select a valid option"
      ;;
  esac
done
