#!/bin/bash

# Enhanced Dev Ports Script for Waybar
CACHE_FILE="/tmp/waybar_dev_ports"
CACHE_DURATION=3  # seconds
CAROUSEL_STATE_FILE="/tmp/waybar_dev_ports_carousel"

# Common development ports to check
DEV_PORTS=(
    # Node.js / Frontend
    3000 3001 3002 3003    # React, Next.js, Node.js
    4000 4001 4200         # Angular, Svelte, misc
    5000 5001 5173         # Flask, dev servers, Vite
    8000 8080 8081         # General web servers
    
    # Backend / API
    8888 8889              # Jupyter, Python servers
    9000 9001 9090         # Various backend services
    
    # Databases
    5432 5433              # PostgreSQL
    3306 3307              # MySQL/MariaDB
    6379 6380              # Redis
    27017 27018            # MongoDB
    
    # Special services
    1313                   # Hugo static site generator
    3333                   # Gatsby development
    4444                   # Jekyll
    6006                   # Storybook
    7000 7001              # Webpack dev server
    8181                   # Tomcat alternate
    9999                   # Various dev tools
    
    # Docker / Container common ports
    2375 2376              # Docker daemon
    5672                   # RabbitMQ
    9200 9300              # Elasticsearch
    8086                   # InfluxDB
)

# Function to check if a port is in use
check_port() {
    local port=$1
    ss -tuln | grep -q ":$port " && return 0 || return 1
}

# Function to update cache
update_cache() {
    local active_ports=()
    
    for port in "${DEV_PORTS[@]}"; do
        if check_port $port; then
            # Check if port is already in array (avoid duplicates)
            if [[ ! " ${active_ports[*]} " =~ " ${port} " ]]; then
                active_ports+=("$port")
            fi
        fi
    done
    
    # Write active ports and timestamp
    printf '%s\n' "${active_ports[@]}" > "$CACHE_FILE"
    echo "$(date +%s)" >> "$CACHE_FILE"
}

# Function to read from cache
read_cache() {
    if [[ -f "$CACHE_FILE" ]]; then
        local cache_time=$(tail -1 "$CACHE_FILE")
        local current_time=$(date +%s)
        
        if (( current_time - cache_time < CACHE_DURATION )); then
            head -n -1 "$CACHE_FILE"
            return 0
        fi
    fi
    return 1
}

# Function to get current carousel index
get_carousel_index() {
    local ports=("$@")
    local port_count=${#ports[@]}
    
    if [[ $port_count -eq 0 ]]; then
        echo 0
        return
    fi
    
    # Read current index from state file
    local current_index=0
    if [[ -f "$CAROUSEL_STATE_FILE" ]]; then
        local state_data=($(cat "$CAROUSEL_STATE_FILE"))
        local last_timestamp=${state_data[0]:-0}
        local last_index=${state_data[1]:-0}
        local current_time=$(date +%s)
        
        # If the state is recent (within 10 seconds), use it and increment
        if (( current_time - last_timestamp < 10 )); then
            current_index=$(( (last_index + 1) % port_count ))
        else
            current_index=0
        fi
    fi
    
    # Save current state
    echo "$(date +%s) $current_index" > "$CAROUSEL_STATE_FILE"
    echo $current_index
}

# Function to format output for waybar
format_output() {
    local ports=("$@")
    local port_count=${#ports[@]}
    
    if [[ $port_count -eq 0 ]]; then
        echo '{"text": "󰪥", "tooltip": "No development servers running", "class": "idle"}'
        return
    fi
    
    # Get current port to display (carousel behavior)
    local carousel_index=$(get_carousel_index "${ports[@]}")
    local current_port="${ports[$carousel_index]}"
    
    # Build text display
    local text="󰖟 :$current_port"
    if [[ $port_count -gt 1 ]]; then
        text+=" ($((carousel_index + 1))/$port_count)"
    fi
    
    # Build tooltip with all ports
    local tooltip="Development servers:\n"
    for i in "${!ports[@]}"; do
        local port="${ports[$i]}"
        if [[ $i -eq $carousel_index ]]; then
            tooltip+="• http://localhost:$port (current)\n"
        else
            tooltip+="• http://localhost:$port\n"
        fi
    done
    tooltip="${tooltip%\\n}"  # Remove trailing newline
    
    echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"active\"}"
}

# Handle click events
handle_click() {
    local ports=("$@")
    [[ ${#ports[@]} -eq 0 ]] && return
    
    case "$1" in
        "left")
            # Get current carousel port and open it
            local carousel_index=$(get_carousel_index "${ports[@]}")
            local current_port="${ports[$carousel_index]}"
            xdg-open "http://localhost:$current_port" 2>/dev/null &
            ;;
        "right")
            # Cycle through ports or open all
            if [[ ${#ports[@]} -le 3 ]]; then
                # Open all if 3 or fewer
                for port in "${ports[@]}"; do
                    xdg-open "http://localhost:$port" 2>/dev/null &
                    sleep 0.2
                done
            else
                # Show selection menu
                local choice=$(printf '%s\n' "${ports[@]}" | wofi --dmenu --prompt "Select port:")
                [[ -n "$choice" ]] && xdg-open "http://localhost:$choice" 2>/dev/null &
            fi
            ;;
    esac
}

# Main execution
main() {
    # Handle click events first
    if [[ "$1" == "--click-left" ]]; then
        local ports=($(read_cache 2>/dev/null))
        handle_click "left" "${ports[@]}"
        exit 0
    elif [[ "$1" == "--click-right" ]]; then
        local ports=($(read_cache 2>/dev/null))
        handle_click "right" "${ports[@]}"
        exit 0
    fi
    
    # Try to read from cache first
    local cached_ports
    if cached_ports=($(read_cache 2>/dev/null)); then
        ports=("${cached_ports[@]}")
    else
        # Update cache if stale or missing
        update_cache
        ports=($(read_cache 2>/dev/null))
    fi
    
    # Format and output for waybar
    format_output "${ports[@]}"
}

main "$@"