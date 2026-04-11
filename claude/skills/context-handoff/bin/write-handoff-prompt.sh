#!/bin/bash
# write-handoff-prompt.sh
# Saves a handoff prompt to a file
#
# Usage: write-handoff-prompt.sh [--quiet] [--output FILE] "prompt content"
#    or: echo "prompt content" | write-handoff-prompt.sh [--quiet] [--output FILE]
#
# Options:
#   --quiet:       Only output the file path (for capturing in scripts)
#   --output FILE: Write to specified file instead of auto-generated path
#
# Output: The file path is always printed to stdout (last line).
#         With --quiet, ONLY the file path is printed.

set -e

HANDOFF_DIR="$HOME/.claude/handoff-prompts"
mkdir -p "$HANDOFF_DIR"

QUIET=false
OUTPUT_FILE=""

# Parse options
while [[ "$1" == --* ]]; do
  case "$1" in
    --quiet)
      QUIET=true
      shift
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Error: Unknown option $1" >&2
      exit 1
      ;;
  esac
done

# Determine output file path
if [[ -n "$OUTPUT_FILE" ]]; then
  # Use explicit output path
  prompt_file="$OUTPUT_FILE"
  # Ensure parent directory exists
  mkdir -p "$(dirname "$prompt_file")"
else
  # Auto-generate path from tmux identifiers
  if [[ -z "$TMUX_PANE" ]]; then
    echo "Error: Not running in tmux (TMUX_PANE not set) and no --output specified" >&2
    exit 1
  fi

  # Get session, window, and pane IDs for fully unique naming
  # This prevents collisions across sessions, windows, and panes
  session_name=$(tmux display-message -p '#{session_name}')
  window_id=$(tmux display-message -p '#{window_id}')
  pane_id="${TMUX_PANE#%}"

  # Sanitize identifiers for filename (remove special chars)
  window_id="${window_id#@}"
  prompt_file="$HANDOFF_DIR/s${session_name}-w${window_id}-p${pane_id}.md"
fi

# Read prompt from argument or stdin
if [[ -n "$1" ]]; then
  prompt="$1"
else
  prompt="$(cat)"
fi

if [[ -z "$prompt" ]]; then
  echo "Error: No prompt provided" >&2
  exit 1
fi

# Write to pane-specific file
echo "$prompt" > "$prompt_file"

# Also copy to clipboard for visibility/editing
if ! $QUIET; then
  echo "Handoff prompt saved: $prompt_file" >&2
  if command -v pbcopy &>/dev/null; then
    echo "$prompt" | pbcopy
    echo "Also copied to clipboard" >&2
  elif command -v xclip &>/dev/null; then
    echo "$prompt" | xclip -selection clipboard
    echo "Also copied to clipboard" >&2
  fi
fi

# Always output the file path to stdout (for capture)
echo "$prompt_file"
