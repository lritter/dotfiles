#!/bin/bash
# run-handoff.sh
# Sends a handoff prompt to the current tmux pane
#
# Usage: run-handoff.sh [options] [prompt-file]
#   --clear:       Send /clear before the prompt
#   --keep:        Don't delete the prompt file after sending
#   --delay <sec>: Schedule send after delay (exits immediately, runs in background)
#   prompt-file:   Path to prompt file (default: ~/.claude/handoff-prompts/pane-<id>.md)
#
# Typically called after exiting Claude, or from a hook.
# Use --delay when calling from within Claude so it can return to input loop.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HANDOFF_DIR="$HOME/.claude/handoff-prompts"
DO_CLEAR=false
DELETE_FILE=true
DELAY=""
PROMPT_FILE=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clear)
      DO_CLEAR=true
      shift
      ;;
    --keep)
      DELETE_FILE=false
      shift
      ;;
    --delay)
      DELAY="$2"
      shift 2
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      PROMPT_FILE="$1"
      shift
      ;;
  esac
done

# If no file specified, use pane-based default
if [[ -z "$PROMPT_FILE" ]]; then
  if [[ -z "$TMUX_PANE" ]]; then
    echo "Error: No prompt file specified and not running in tmux" >&2
    exit 1
  fi
  pane_id="${TMUX_PANE#%}"
  PROMPT_FILE="$HANDOFF_DIR/pane-${pane_id}.md"
fi

# Check for handoff file
if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "No handoff prompt found: $PROMPT_FILE"
  exit 0
fi

# Require tmux for send-keys
if [[ -z "$TMUX_PANE" ]]; then
  echo "Error: Not running in tmux (TMUX_PANE not set)" >&2
  exit 1
fi

prompt="$(cat "$PROMPT_FILE")"

# If --delay specified, use send-keys-delayed.sh and exit immediately
if [[ -n "$DELAY" ]]; then
  # Write prompt to temp file for delayed send (don't delete original yet)
  TEMP_PROMPT=$(mktemp)
  cat "$PROMPT_FILE" > "$TEMP_PROMPT"

  if $DO_CLEAR; then
    # Schedule /clear first
    "$SCRIPT_DIR/send-keys-delayed.sh" "$DELAY" "/clear" Enter
    # Schedule prompt after /clear has time to complete
    PROMPT_DELAY=$(echo "$DELAY + 0.5" | bc)
    "$SCRIPT_DIR/send-keys-delayed.sh" "$PROMPT_DELAY" --literal --file "$TEMP_PROMPT"
    # Schedule Enter to submit the prompt
    ENTER_DELAY=$(echo "$PROMPT_DELAY + 0.2" | bc)
    "$SCRIPT_DIR/send-keys-delayed.sh" "$ENTER_DELAY" Enter
  else
    "$SCRIPT_DIR/send-keys-delayed.sh" "$DELAY" --literal --file "$TEMP_PROMPT"
    # Schedule Enter to submit the prompt
    ENTER_DELAY=$(echo "$DELAY + 0.2" | bc)
    "$SCRIPT_DIR/send-keys-delayed.sh" "$ENTER_DELAY" Enter
  fi

  # Clean up original file (temp file cleaned up by delayed script? no, we need to handle that)
  # Actually, keep temp file since background process needs it. It's in /tmp so will be cleaned eventually.
  if $DELETE_FILE; then
    rm "$PROMPT_FILE"
  fi

  echo "Handoff scheduled in ${DELAY}s"
  exit 0
fi

# Immediate mode (no delay)
prompt="$(cat "$PROMPT_FILE")"

# Clean up the file (unless --keep)
if $DELETE_FILE; then
  rm "$PROMPT_FILE"
fi

if $DO_CLEAR; then
  # Send /clear command
  tmux send-keys "/clear" Enter
  sleep 0.3
fi

# Send the prompt
# Using send-keys with literal flag to handle special characters
tmux send-keys -l "$prompt"

echo "Handoff prompt sent (from $PROMPT_FILE)"
