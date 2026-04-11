#!/usr/bin/env bash
# Reads Claude context info for any pane in the current tmux window
# Arg 1: pane TTY (used as fallback)
# Arg 2: window ID (e.g., @123) - needed for status line context

FALLBACK_TTY="${1#/dev/}"
WINDOW_ID="$2"
STALE_SECONDS=3600 # 1 hour - fallback cleanup for orphaned files

# Powerline characters (UTF-8 bytes for U+E0B6 and U+E0B4)
LEFT_CAP=$(printf '\xee\x82\xb6')
RIGHT_CAP=$(printf '\xee\x82\xb4')

# Color scale based on context usage (Catppuccin Mocha palette)
# Format: "threshold:bg_color:text_color"
# Thresholds are checked in order - first match wins
COLOR_SCALE=(
  "90:#f38ba8:#1e1e2e" # Red - critical
  "75:#fab387:#1e1e2e" # Peach - high
  "50:#f9e2af:#1e1e2e" # Yellow - medium
  "25:#89b4fa:#1e1e2e" # Blue - low
  "0:#a6e3a1:#1e1e2e"  # Green - minimal
)

# Get colors based on usage percentage
get_colors() {
  local pct=$1
  for entry in "${COLOR_SCALE[@]}"; do
    IFS=':' read -r threshold bg txt <<<"$entry"
    if [[ $pct -ge $threshold ]]; then
      echo "$bg $txt"
      return
    fi
  done
  echo "#a6e3a1 #1e1e2e"
}

# Get all TTYs in the specified tmux window (strip /dev/ prefix)
get_window_ttys() {
  local window_target="$1"
  if [[ -n "$window_target" ]]; then
    tmux list-panes -t "$window_target" -F '#{pane_tty}' 2>/dev/null | sed 's|^/dev/||'
  else
    tmux list-panes -F '#{pane_tty}' 2>/dev/null | sed 's|^/dev/||'
  fi
}

# Check if Claude (node process) is running on a given TTY
claude_running_on_tty() {
  pgrep -t "$1" -x "node" >/dev/null 2>&1
}

# Build list of TTYs to check (all panes in current window)
mapfile -t WINDOW_TTYS < <(get_window_ttys "$WINDOW_ID")

# Fallback to passed argument if tmux command fails
if [[ ${#WINDOW_TTYS[@]} -eq 0 ]]; then
  WINDOW_TTYS=("$FALLBACK_TTY")
fi

# Convert to associative array for fast lookup
declare -A TTY_MAP
for tty in "${WINDOW_TTYS[@]}"; do
  TTY_MAP["$tty"]=1
done

# Find the newest matching status file
best_file=""
best_timestamp=0
best_percent=""
best_model=""
best_tty=""

for STATUS_FILE in /tmp/claude-context-status-*; do
  [[ -f "$STATUS_FILE" ]] || continue

  IFS='|' read -r percent model timestamp file_tty <"$STATUS_FILE"

  # Check if this file matches any TTY in our window
  if [[ -n "${TTY_MAP[$file_tty]}" ]]; then
    now=$(date +%s)
    age=$((now - timestamp))

    # Check if valid (Claude running or not stale)
    if claude_running_on_tty "$file_tty" || [[ $age -lt $STALE_SECONDS ]]; then
      # Keep track of newest
      if [[ $timestamp -gt $best_timestamp ]]; then
        best_file="$STATUS_FILE"
        best_timestamp="$timestamp"
        best_percent="$percent"
        best_model="$model"
        best_tty="$file_tty"
      fi
    else
      # Stale and no Claude process - clean up orphaned file
      rm -f "$STATUS_FILE"
    fi
  fi
done

# Output the best match if found
if [[ -n "$best_file" ]]; then
  read -r color text <<<"$(get_colors "$best_percent")"
  echo "#[fg=${color},bg=default]${LEFT_CAP}#[fg=${text},bg=${color}] ${best_model} ${best_percent}% #[fg=${color},bg=default]${RIGHT_CAP} "
else
  echo ""
fi
