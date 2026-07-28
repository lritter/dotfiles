#!/bin/bash
# Click-to-focus handler for Claude Code notifications.
#
# Invoked by `terminal-notifier -execute` when the user clicks a notification.
# Receives the originating tmux target as "$1" in the form session:window.pane.
# Selects that window and pane, then brings Ghostty to the foreground.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATHS_ENV="$SCRIPT_DIR/paths.env"

if [[ ! -f "$PATHS_ENV" ]]; then
  echo "ghostty-focus.sh: missing $PATHS_ENV — run setup-notifications.sh" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$PATHS_ENV"

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
  echo "ghostty-focus.sh: no tmux target provided" >&2
  exit 1
fi

# Split session:window.pane into window-scope and pane-scope forms.
WINDOW_TARGET="${TARGET%.*}"     # session:window
PANE_TARGET="$TARGET"             # session:window.pane

"$TMUX_BIN" select-window -t "$WINDOW_TARGET" 2>/dev/null || true
"$TMUX_BIN" select-pane   -t "$PANE_TARGET"   2>/dev/null || true

"$OSASCRIPT" -e 'tell application "Ghostty" to activate' >/dev/null 2>&1 || true
