set -eu

# Up             -> volume up
# Down           -> volume down
# Up 300ms       -> next track        (Mode Skip) 
# Down 300ms     -> previous track    (Mode Skip)
# Up 300ms       -> pause track       (Mode Flash/Pause) 
# Down 300ms     -> toggle flashlight (Mode Flash/Pause)
# Up/Down 1300ms -> toggle between modes (Skip and Flash/Pause)

TO_ACTION=0.300
TO_REMAINING_MC=1.000 
DUR_S=25

SKIP_MODE=1
TORCH_STATE=0

toggle_flashlight() {
    cmd vibrate $DUR_S
    if [ "$TORCH_STATE" -eq 0 ]; then
        cmd torch on
        TORCH_STATE=1
    else
        cmd torch off
        TORCH_STATE=0
    fi
}

change_mode() {
    if [ "$SKIP_MODE" -eq 0 ]; then 
        SKIP_MODE=1; 
    else 
        SKIP_MODE=0; 
    fi
    # Uncomment to receive notifications about mode change.
    # cmd notify -t "Keysh" -c "Mode: $( [ "$SKIP_MODE" -eq 1 ] && echo "Skip" || echo "Flash/Pause" )"
}

on_up() {
    if read_key -t $TO_ACTION; then
        cmd volume current up
        return
    fi

    cmd vibrate $DUR_S    
    if read_key -t $TO_REMAINING_MC; then
        if [ "$SKIP_MODE" -eq 1 ]; then
            cmd media next
        else
            cmd media play_pause
        fi
        return
    fi

    cmd vibrate $DUR_S
    change_mode
}

on_down() {
    if read_key -t $TO_ACTION; then
        cmd volume current down
        return
    fi

    cmd vibrate $DUR_S
    if read_key -t $TO_REMAINING_MC; then
        if [ "$SKIP_MODE" -eq 1 ]; then
            cmd media previous
        else
            toggle_flashlight
        fi
        return
    fi

    cmd vibrate $DUR_S
    change_mode
}

read_key() {
    while read $@ key; do
        case "$key" in
        "app:"* )
            on_app "$key" ;;
        * )
            return 0 ;;
        esac
    done
    return 1
}

    
on_app() {
    data="${1#*:}"
    pkg="${data%%:*}"
    
    case "$EXCLUDE_APPS " in 
    *"$pkg "* )
        [ "$WORK" = "1" ] && self PAUSE
        WORK=0 ;;
    * )
        [ "$WORK" = "0" ] && self RESUME
        WORK=1 ;;
    esac
}


loop() {
    while read_key; do
    case "$key" in
        "$PRESS_UP" )
            on_up
        ;;
        "$PRESS_DOWN" )
            on_down
        ;;
    esac
    done
}


encode_list() {
    ENCODED=""; for arg in "$@"; do
        ENCODED="${ENCODED}${#arg}:${arg}"
    done
    ENCODED="${#ENCODED}:$ENCODED"
}
cmd() {
    encode_list "$@"; 
    echo "$ENCODED"
}

loop
