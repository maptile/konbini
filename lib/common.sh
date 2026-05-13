#!/usr/bin/env bash

echoLargeText() {
    local text="$1"
    local color="$2"

    # Define the color palette
    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local MAGENTA="\033[35m"
    local CYAN="\033[36m"
    local RESET="\033[0m"

    # Default color
    local color_code="$RESET"

    # Select the color based on the input
    case "$color" in
        red) color_code="$RED" ;;
        green) color_code="$GREEN" ;;
        yellow) color_code="$YELLOW" ;;
        blue) color_code="$BLUE" ;;
        magenta) color_code="$MAGENTA" ;;
        cyan) color_code="$CYAN" ;;
        *) color_code="$RESET" ;; # Fall back to the default color if nothing matches
    esac

    # Check whether figlet/toilet is installed
    if command -v toilet >/dev/null 2>&1; then
        echo -e "${color_code}$(toilet -f smmono12 -w 100 "$text")${RESET}"
    elif command -v figlet >/dev/null 2>&1; then
        echo -e "${color_code}$(figlet -W -f banner -w 100 "$text")${RESET}"
    else
        echo -e "${color_code}$text${RESET}"
    fi
}

echoText() {
    local text="$1"
    local color="$2"

    # Define the color palette
    local RED="\033[31m"
    local GREEN="\033[32m"
    local YELLOW="\033[33m"
    local BLUE="\033[34m"
    local MAGENTA="\033[35m"
    local CYAN="\033[36m"
    local RESET="\033[0m"

    # Default color
    local color_code="$RESET"

    # Select the color based on the input
    case "$color" in
        red) color_code="$RED" ;;
        green) color_code="$GREEN" ;;
        yellow) color_code="$YELLOW" ;;
        blue) color_code="$BLUE" ;;
        magenta) color_code="$MAGENTA" ;;
        cyan) color_code="$CYAN" ;;
        *) color_code="$RESET" ;; # Fall back to the default color if nothing matches
    esac

    echo -e "${color_code}$text${RESET}"
}

userConfirmDir() {
    echo ""
    echo "Current working directory is:"
    echo "$1"
    echo ""
    read -n 1 -p "Use this directory? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo
        echo "OK, running..."
        return 0
    else
        return 1
    fi
}

requireSecretTool() {
    command -v secret-tool >/dev/null 2>&1 || {
        echo "Error: secret-tool not found. Install with: sudo apt install libsecret-tools" >&2
        return 127
    }
}

readApiKey() {
    requireSecretTool || return $?
    local service="$1"
    [ -n "$service" ] || { echo "Usage: readApiKey <service>" >&2; return 2; }
    secret-tool lookup service "$service" 2>/dev/null
}

writeApiKey() {
    requireSecretTool || return $?
    local service="$1"
    local provided_key="$2"
    [ -n "$service" ] || { echo "Usage: writeApiKey <service> [key]" >&2; return 2; }

    local k1 k2
    if [ -n "$provided_key" ]; then
        k1="$provided_key"
        k2="$provided_key"
    else
        echo "Enter API key for service='$service' (input hidden). Press Ctrl+C to abort." >&2
        read -r -s -p "API key: " k1; echo >&2
        read -r -s -p "Confirm : " k2; echo >&2
    fi

    if [ -z "$k1" ] || [ "$k1" != "$k2" ]; then
        echo "Error: empty or mismatch. Aborted." >&2
        unset k1 k2
        return 1
    fi

    if ! printf %s "$k1" | secret-tool store --label="Personal API Key for $service" service "$service" ; then
        echo "Error: failed to store key via secret-tool." >&2
        unset k1 k2
        return 1
    fi

    unset k1 k2
}

getApiKey() {
    # Backward-compatible behavior: read first, then prompt to save if missing, then read again
    local service="$1"
    [ -n "$service" ] || { echo "Usage: getApiKey <service>" >&2; return 2; }

    local key
    key=$(readApiKey "$service")
    if [ -z "$key" ]; then
        writeApiKey "$service" || return 1
        key=$(readApiKey "$service")
    fi
    [ -n "$key" ] || { echo "Error: failed to obtain API key." >&2; return 1; }
    echo "$key"
}

# Helper function for sending desktop notifications
send_notification() {
    local title="$1"
    local message="$2"
    local urgency="${3:-normal}"

    # Check whether notify-send is available
    if ! command -v notify-send &> /dev/null; then
        return
    fi

    # Get the current user
    local user="${USER:-$(whoami)}"

    # Try to obtain DISPLAY and DBUS addresses from the user's processes
    local user_id=$(id -u "$user")

    # Find the user's display session
    local display=$(ps -u "$user" e | grep -Eo 'DISPLAY=[^ ]+' | head -n1 | cut -d= -f2)
    local dbus=$(ps -u "$user" e | grep -Eo 'DBUS_SESSION_BUS_ADDRESS=[^ ]+' | head -n1 | cut -d= -f2-)

    # If nothing is found, try common defaults
    if [ -z "$display" ]; then
        display=":0"
    fi

    if [ -z "$dbus" ]; then
        # Try to obtain the DBUS address from a common location
        if [ -f "/run/user/$user_id/bus" ]; then
            dbus="unix:path=/run/user/$user_id/bus"
        fi
    fi

    # Set environment variables and send the notification
    if [ -n "$display" ] && [ -n "$dbus" ]; then
        DISPLAY="$display" DBUS_SESSION_BUS_ADDRESS="$dbus" notify-send -u "$urgency" "$title" "$message"
    fi
}

change_eat_title() {
    local name_b64 title_b64
    name_b64=$(printf '%s' 'rename-buffer' | base64 | tr -d '\n')
    title_b64=$(printf '%s' "$*" | base64 | tr -d '\n')
    printf '\033]51;e;M;%s;%s\007' "$name_b64" "$title_b64"
}

change_vterm_title() {
    echo -ne "\033]0;$1\007"
}

is_kitty_term() {
    [[ "$TERM" == xterm-kitty* ]]
}

set_tab_title() {
    if is_kitty_term; then
        kitten @ set-tab-title "$1"
    fi

    change_eat_title "$1"
    change_vterm_title "$1"
}

reset_tab_title() {
    if is_kitty_term; then
        kitten @ set-tab-title
    fi
}

set_tab_color() {
    if is_kitty_term; then
        kitten @ set-tab-color "$1"
    fi
}

reset_tab_color() {
    if is_kitty_term; then
        kitten @ set-tab-color active_fg=NONE active_bg=NONE inactive_fg=NONE inactive_bg=NONE
    fi
}

kssh() {
    if is_kitty_term; then
        echo 'ssh using kitten'
        kitten ssh "$@"
    else
        echo 'ssh using ssh'
        ssh "$@"
    fi
}

printCountDown(){
    echo "$1 after $2 seconds"

    for ((i = $2 ; i > 0 ; i--)); do
        echo "$i"
        sleep 1
    done
}
