#!/usr/bin/env bash
# Called by Claude Code's Stop hook to clean up status file on session end
# Receives JSON via stdin with session_id

input=$(cat)
session_id=$(echo "$input" | jq -r '.session_id // ""')

if [[ -n "$session_id" ]]; then
    rm -f "/tmp/claude-context-status-${session_id}"
fi
