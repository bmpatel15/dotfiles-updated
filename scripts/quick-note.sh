#!/usr/bin/env bash

NOTES_DIR="$HOME/notes"
TEMPLATES_DIR="$NOTES_DIR/_Meta"
YEAR=$(date +%Y)
MONTH=$(date +%m-%B)
DAY=$(date +%A)
NOTE_NAME="$(date +%Y-%m-%d)-$DAY.md"
NOTE_PATH="$NOTES_DIR/daily/$YEAR/$MONTH/$NOTE_NAME"
SESSION_NAME="daily-note"

# Ensure directory exists
mkdir -p "$NOTES_DIR/daily/$YEAR/$MONTH"

# If file doesn't exist or is empty, create from template
if [ ! -s "$NOTE_PATH" ]; then
    # Calculate yesterday and tomorrow
    YESTERDAY=$(date -d "yesterday" +%Y-%m-%d-%A 2>/dev/null || date -v-1d +%Y-%m-%d-%A)
    TOMORROW=$(date -d "tomorrow" +%Y-%m-%d-%A 2>/dev/null || date -v+1d +%Y-%m-%d-%A)
    CURRENT_DATE=$(date +%Y-%m-%d)
    CURRENT_TIME=$(date '+%Y-%m-%d %H:%M')
    
    # Create from template
    if [ -f "$TEMPLATES_DIR/daily-note.md" ]; then
        sed -e "s/{{date}}/$CURRENT_DATE/g" \
            -e "s/{{day}}/$DAY/g" \
            -e "s/{{yesterday}}/$YESTERDAY/g" \
            -e "s/{{tomorrow}}/$TOMORROW/g" \
            -e "s/{{timestamp}}/$CURRENT_TIME/g" \
            "$TEMPLATES_DIR/daily-note.md" > "$NOTE_PATH"
    else
        # Fallback if template doesn't exist
        echo "# $CURRENT_DATE - $DAY" > "$NOTE_PATH"
        echo "" >> "$NOTE_PATH"
        echo "## Daily note" >> "$NOTE_PATH"
    fi
fi

# Launch tmux session
exec tmux new-session -A -s "$SESSION_NAME" "cd $NOTES_DIR && nvim '$NOTE_PATH'"
