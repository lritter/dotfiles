#!/usr/bin/env bash
# Called by Claude Code's statusline feature
# Receives JSON via stdin, writes context info to a file for tmux to read

# Read JSON from stdin
input=$(cat)

# Extract session_id for unique file naming
session_id=$(echo "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
STATUS_FILE="/tmp/claude-context-status-${session_id}"

# Extract context info using jq
percent=$(echo "$input" | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
model=$(echo "$input" | jq -r '.model.display_name // "Claude"' 2>/dev/null)

# Round to integer
percent_int=$(printf "%.0f" "$percent" 2>/dev/null || echo "0")

# Get the TTY from the parent Claude process (since this script runs without a TTY)
# Walk up the process tree to find one with a TTY
current_tty=""
pid=$$
while [[ -z "$current_tty" || "$current_tty" == "??" ]] && [[ $pid -gt 1 ]]; do
    current_tty=$(ps -p $pid -o tty= 2>/dev/null | tr -d ' ')
    pid=$(ps -p $pid -o ppid= 2>/dev/null | tr -d ' ')
done

# Write to status file with timestamp and TTY
echo "${percent_int}|${model}|$(date +%s)|${current_tty}" > "$STATUS_FILE"

# Output nothing - we don't need Claude Code's built-in status display
echo ""
