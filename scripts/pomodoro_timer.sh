#!/bin/bash

# --- Configuration ---
WORK_MINUTES=40 # Default value

# Parse command-line arguments
while getopts "t:" opt; do
  case $opt in
    t)
      if [[ $OPTARG =~ ^[0-9]+$ ]] && [ "$OPTARG" -gt 0 ]; then
        WORK_MINUTES=$OPTARG
      else
        echo "Error: -t requires a positive integer argument for minutes." >&2
        exit 1
      fi
      ;;
    \?)
      echo "Usage: $0 [-t <minutes>]" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

# Check for required commands
SOUND_FILE="/usr/share/sounds/freedesktop/stereo/complete.oga" # Default system sound

# Check for required commands
if ! command -v notify-send &> /dev/null; then
    echo "Error: notify-send (libnotify) is not installed."
    exit 1
fi

# Use 'paplay' (PulseAudio/PipeWire) or 'play' (sox) for sound
if command -v paplay &> /dev/null; then
    PLAY_CMD="paplay"
elif command -v play &> /dev/null; then
    PLAY_CMD="play"
else
    echo "Error: No suitable audio player (paplay or play) found."
    exit 1
fi

# --- Pomodoro Logic ---
echo "Starting Pomodoro: $WORK_MINUTES minutes of focus."
notify-send -u normal "Pomodoro Started" "Time to focus for $WORK_MINUTES minutes."

# Timer countdown with progress bar
TOTAL_SECONDS=$((WORK_MINUTES * 60))
BAR_WIDTH=40
BAR_STR="################################################################################"
EMPTY_STR="--------------------------------------------------------------------------------"

for ((i=0; i<=TOTAL_SECONDS; i++)); do
    PERCENT=$((i * 100 / TOTAL_SECONDS))
    COMPLETED=$((i * BAR_WIDTH / TOTAL_SECONDS))
    REMAINING=$((BAR_WIDTH - COMPLETED))
    
    # Calculate elapsed time for display
    ELAPSED_MIN=$((i / 60))
    ELAPSED_SEC=$((i % 60))
    
    printf "\r[%s%s] %d%% (%02d:%02d/%02d:00)" \
        "${BAR_STR:0:$COMPLETED}" \
        "${EMPTY_STR:0:$REMAINING}" \
        "$PERCENT" \
        "$ELAPSED_MIN" \
        "$ELAPSED_SEC" \
        "$WORK_MINUTES"
    
    if [ "$i" -lt "$TOTAL_SECONDS" ]; then
        sleep 1
    fi
done
echo ""

# --- Alert User ---
echo "Pomodoro finished! Take a break."
notify-send -u normal "Pomodoro Finished!" "Time for a break!"

# Play notification sound
if [ -f "$SOUND_FILE" ]; then
    $PLAY_CMD "$SOUND_FILE"
else
    echo "Sound file not found. Check SOUND_FILE path in script."
    # Fallback: play a simple system bell
    echo -e '\a'
fi

# Notes:
# Remember to make the script executable: chmod +x ~/pomodoro.sh
