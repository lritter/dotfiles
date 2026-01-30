#!/bin/bash
# run-handoff.sh
# Checks for a handoff prompt and sends it to the current tmux pane
#
# Usage: run-handoff.sh [--clear]
#   --clear: Send /clear before the prompt (default: prompt only)
#
# Typically called after exiting Claude, or from a hook

set -e

HANDOFF_DIR="$HOME/.claude/handoff-prompts"
DO_CLEAR=false

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear)
      DO_CLEAR=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Get tmux pane identifier
if [[ -z "$TMUX_PANE" ]]; then
  echo "Error: Not running in tmux (TMUX_PANE not set)" >&2
  exit 1
fi

pane_id="${TMUX_PANE#%}"
prompt_file="$HANDOFF_DIR/pane-${pane_id}.md"

# Check for handoff file
if [[ ! -f "$prompt_file" ]]; then
  echo "No handoff prompt found for pane $pane_id"
  exit 0
fi

prompt="$(cat "$prompt_file")"

# Clean up the file
rm "$prompt_file"

if $DO_CLEAR; then
  # Send /clear command
  tmux send-keys "/clear" Enter
  sleep 0.3
fi

# Send the prompt
# Using send-keys with literal flag to handle special characters
tmux send-keys -l "$prompt"

echo "Handoff prompt sent to pane $pane_id"
