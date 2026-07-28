#!/usr/bin/env bash
# Set a per-window tmux option reflecting Claude's state, so the window tab can
# show an indicator. Invoked by Claude Code hooks (UserPromptSubmit / Stop /
# Notification) with the state as $1: working | idle | waiting.
#
# Like notify.sh, hooks run with a minimal PATH, so pull the tmux path from
# paths.env. The claude pane exports $TMUX_PANE, inherited here, which tmux
# resolves to the owning window.
set -u

STATE="${1:-}"
[ -n "$STATE" ] || exit 0
[ -n "${TMUX_PANE:-}" ] || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
[ -f "$SCRIPT_DIR/paths.env" ] && . "$SCRIPT_DIR/paths.env"
TMUX_BIN="${TMUX_BIN:-tmux}"

"$TMUX_BIN" set-option -w -t "$TMUX_PANE" @claude_state "$STATE" 2>/dev/null || true
