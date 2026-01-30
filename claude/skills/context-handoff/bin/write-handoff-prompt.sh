#!/bin/bash
# write-handoff-prompt.sh
# Saves a handoff prompt for the current tmux pane
#
# Usage: echo "prompt content" | write-handoff-prompt.sh
#    or: write-handoff-prompt.sh "prompt content"

set -e

HANDOFF_DIR="$HOME/.claude/handoff-prompts"
mkdir -p "$HANDOFF_DIR"

# Get tmux pane identifier (e.g., %0, %1)
if [[ -z "$TMUX_PANE" ]]; then
  echo "Error: Not running in tmux (TMUX_PANE not set)" >&2
  exit 1
fi

# Sanitize pane ID for filename (remove %)
pane_id="${TMUX_PANE#%}"
prompt_file="$HANDOFF_DIR/pane-${pane_id}.md"

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
echo "Handoff prompt saved: $prompt_file"

# Also copy to clipboard for visibility/editing
if command -v pbcopy &>/dev/null; then
  echo "$prompt" | pbcopy
  echo "Also copied to clipboard"
elif command -v xclip &>/dev/null; then
  echo "$prompt" | xclip -selection clipboard
  echo "Also copied to clipboard"
fi
