#!/bin/bash

POMO_FILE="/tmp/pomodoro_state"
WORK_MINS=25
BREAK_MINS=5

notify() {
    notify-send -u critical "󰔛 Pomodoro" "$1" -t 10000
}

case "$1" in
    start)
        if [[ ! -f "$POMO_FILE" ]] || grep -q "standby" "$POMO_FILE"; then
            echo "$(($(date +%s) + WORK_MINS * 60)):work:running" > "$POMO_FILE"
        fi
        ;;
    break)
        echo "$(($(date +%s) + BREAK_MINS * 60)):break:running" > "$POMO_FILE"
        ;;
    toggle)
        if [[ -f "$POMO_FILE" ]]; then
            IFS=':' read -r end_time mode state < "$POMO_FILE"
            if [[ "$state" == "paused" ]]; then
                remaining=$(cat "${POMO_FILE}.remaining" 2>/dev/null || echo 0)
                echo "$(($(date +%s) + remaining)):$mode:running" > "$POMO_FILE"
                rm -f "${POMO_FILE}.remaining"
            elif [[ "$state" == "running" ]]; then
                remaining=$((end_time - $(date +%s)))
                echo "$remaining" > "${POMO_FILE}.remaining"
                echo "$end_time:$mode:paused" > "$POMO_FILE"
            fi
        fi
        ;;
    reset)
        rm -f "$POMO_FILE" "${POMO_FILE}.remaining"
        ;;
    add)
        if [[ -f "$POMO_FILE" ]]; then
            IFS=':' read -r end_time mode state < "$POMO_FILE"
            if [[ "$state" == "paused" ]]; then
                remaining=$(cat "${POMO_FILE}.remaining" 2>/dev/null || echo 0)
                echo "$((remaining + 60))" > "${POMO_FILE}.remaining"
            fi
        fi
        ;;
    sub)
        if [[ -f "$POMO_FILE" ]]; then
            IFS=':' read -r end_time mode state < "$POMO_FILE"
            if [[ "$state" == "paused" ]]; then
                remaining=$(cat "${POMO_FILE}.remaining" 2>/dev/null || echo 60)
                new_remaining=$((remaining - 60))
                [[ $new_remaining -gt 0 ]] && echo "$new_remaining" > "${POMO_FILE}.remaining"
            fi
        fi
        ;;
    *)
        if [[ -f "$POMO_FILE" ]]; then
            IFS=':' read -r end_time mode state < "$POMO_FILE"
            
            if [[ "$state" == "paused" ]]; then
                remaining=$(cat "${POMO_FILE}.remaining" 2>/dev/null || echo 0)
                mins=$((remaining / 60))
                secs=$((remaining % 60))
                printf '{"text": "󰏤 %02d:%02d", "class": "paused", "tooltip": "Paused (%s)\\nClick: resume | Middle: reset"}' "$mins" "$secs" "$mode"
            elif [[ "$state" == "running" ]]; then
                remaining=$((end_time - $(date +%s)))
                if [[ $remaining -le 0 ]]; then
                    if [[ "$mode" == "work" ]]; then
                        notify "Work session complete! Take a break."
                        echo "$(($(date +%s) + BREAK_MINS * 60)):break:running" > "$POMO_FILE"
                    else
                        notify "Break over! Ready to focus?"
                        rm -f "$POMO_FILE"
                        echo '{"text": "󰔛", "class": "standby", "tooltip": "Click to start 25min focus"}'
                        exit 0
                    fi
                    remaining=$((BREAK_MINS * 60))
                    mode="break"
                fi
                mins=$((remaining / 60))
                secs=$((remaining % 60))
                if [[ "$mode" == "work" ]]; then
                    printf '{"text": "󱎫 %02d:%02d", "class": "work", "tooltip": "Focus time\\nRight: pause | Middle: reset | Scroll: ±1min"}' "$mins" "$secs"
                else
                    printf '{"text": "󰾨 %02d:%02d", "class": "break", "tooltip": "Break time\\nMiddle: reset"}' "$mins" "$secs"
                fi
            else
                echo '{"text": "󰔛", "class": "standby", "tooltip": "Click to start 25min focus"}'
            fi
        else
            echo '{"text": "󰔛", "class": "standby", "tooltip": "Click to start 25min focus"}'
        fi
        ;;
esac
