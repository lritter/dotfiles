#!/usr/bin/env bash
# Toggle a full-height left side-pane running a tool, from a tmux binding.
#
# Usage: toggle-side-pane.sh <marker> <mode> <path> <cmd...>
#   marker  unique tag stored on the pane as @side_marker
#   mode    kill  -> re-press force-closes the pane
#           focus -> re-press just focuses the pane (safe for editors)
#   path    working dir for a newly created pane
#   cmd...  command to run in the pane
#
# Detection uses a pane user option (@side_marker) rather than the pane title,
# because the running tool can overwrite the title via terminal escapes.
set -euo pipefail

marker="$1"
mode="$2"
path="$3"
shift 3

existing=$(tmux list-panes -F '#{pane_id}|#{@side_marker}' |
  awk -F'|' -v m="$marker" '$2 == m { print $1; exit }')

if [ -n "$existing" ]; then
  if [ "$mode" = "focus" ]; then
    tmux select-pane -t "$existing"
  else
    tmux kill-pane -t "$existing"
  fi
else
  tmux split-window -fbh -l 40% -c "$path" "$@"
  tmux set -p @side_marker "$marker"
fi
