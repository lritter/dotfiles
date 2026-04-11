#!/usr/bin/env bash
# SessionStart hook for context-handoff
# Injects pending handoff prompts after /clear

set -euo pipefail

HANDOFF_DIR="$HOME/.claude/handoff-prompts"

# Get current tmux identifiers (if in tmux)
get_handoff_file() {
  if [[ -z "${TMUX_PANE:-}" ]]; then
    return 1
  fi

  # Get session, window, and pane IDs
  local session_name window_id pane_id
  session_name=$(tmux display-message -p '#{session_name}' 2>/dev/null) || return 1
  window_id=$(tmux display-message -p '#{window_id}' 2>/dev/null) || return 1
  window_id="${window_id#@}"
  pane_id="${TMUX_PANE#%}"

  local prompt_file="$HANDOFF_DIR/s${session_name}-w${window_id}-p${pane_id}.md"

  if [[ -f "$prompt_file" ]]; then
    echo "$prompt_file"
    return 0
  fi
  return 1
}

# Escape outputs for JSON using pure bash
escape_for_json() {
  local input="$1"
  local output=""
  local i char
  for (( i=0; i<${#input}; i++ )); do
    char="${input:$i:1}"
    case "$char" in
      $'\\') output+='\\' ;;
      '"') output+='\"' ;;
      $'\n') output+='\n' ;;
      $'\r') output+='\r' ;;
      $'\t') output+='\t' ;;
      *) output+="$char" ;;
    esac
  done
  printf '%s' "$output"
}

# Check for pending handoff prompt
handoff_file=$(get_handoff_file) || handoff_file=""

if [[ -n "$handoff_file" && -f "$handoff_file" ]]; then
  # Read and escape the handoff prompt
  handoff_content=$(cat "$handoff_file")
  handoff_escaped=$(escape_for_json "$handoff_content")

  # Remove the file after reading (consumed)
  rm "$handoff_file"

  # Output context injection as JSON
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<context-handoff>\nThe previous session prepared a handoff prompt for you. Here is the context from the previous session:\n\n${handoff_escaped}\n</context-handoff>"
  }
}
EOF
else
  # No handoff, output empty JSON
  echo '{}'
fi

exit 0
