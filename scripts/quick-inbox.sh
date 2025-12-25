#!/usr/bin/env bash

# Quick Inbox Capture Script
INBOX_FILE="$HOME/notes/0-inbox/quick-captures/$(date +%Y-%m-%d)-quick.md"
SESSION_NAME="quick-inbox"

# Ensure directory exists
mkdir -p "$(dirname "$INBOX_FILE")"

# Launch tmux session (attach if exists, create if not)
exec tmux new-session -A -s "$SESSION_NAME" "nvim + '$INBOX_FILE'"
