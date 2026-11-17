#!/usr/bin/env bash
# tmux file picker over the files Claude wrote/edited this session, newest
# first. Preview with bat; on Enter, open per ~/.config/tmux/claude-openers.conf
# (terminal apps in a full-height left split, GUI apps detached). ctrl-o opens a
# terminal app in its own new Ghostty window instead, which closes on quit.
#
# Meant to be launched from a display-popup binding, given the ORIGIN pane id:
#   bind C-f display-popup -w 80% -h 80% -E \
#     "~/.config/tmux/claude-file-picker.sh '#{pane_id}'"
# (Inside the popup $TMUX_PANE is the popup's own pane, so the origin pane must
# be passed in.)
#
# Data is written by the claude-session-files plugin's record.sh hook.

set -uo pipefail

# Resolve the origin pane (the one focused when the popup opened). A display-popup
# does NOT expand formats in its shell-command arg and runs with $TMUX_PANE unset,
# so a passed-in "#{pane_id}" arrives literal and cannot be trusted. The popup does
# not change the session's active pane, so tmux's active pane is the reliable source.
# Order: an explicit real pane id arg (manual/CLI use) -> active pane -> $TMUX_PANE.
origin="${1:-}"
case "$origin" in %[0-9]*) ;; *) origin="" ;; esac
[ -n "$origin" ] || origin="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
[ -n "$origin" ] || origin="${TMUX_PANE:-}"
state="/tmp/claude-session-files-$(id -u)"
conf="${HOME}/.config/tmux/claude-openers.conf"

note() { printf '%s\n' "$1"; sleep 1.5; }

session_for_pane() {
  local f="$state/panes/${1#%}"
  [ -f "$f" ] && cat "$f"
}

# Resolve the session for the origin pane. If the picker was triggered from a
# side pane (nvim/lazygit/yazi) rather than the Claude pane, fall back to the
# most-recently-active session among all panes in the origin's window.
sid="$(session_for_pane "$origin")"
sid_pane="$origin"
if [ -z "$sid" ] && [ -n "$origin" ]; then
  win="$(tmux display-message -p -t "$origin" '#{window_id}' 2>/dev/null || true)"
  if [ -n "$win" ]; then
    best="" best_mtime=0
    while IFS= read -r p; do
      s="$(session_for_pane "$p")"; [ -n "$s" ] || continue
      lg="$state/sessions/$s.log"; [ -f "$lg" ] || continue
      m="$(stat -f %m "$lg" 2>/dev/null || echo 0)"
      if [ "$m" -gt "$best_mtime" ]; then best_mtime="$m"; best="$s"; best_pane="$p"; fi
    done < <(tmux list-panes -t "$win" -F '#{pane_id}' 2>/dev/null)
    sid="$best" sid_pane="${best_pane:-}"
  fi
fi

[ -n "$sid" ] || { note "No Claude session recorded for this pane/window."; exit 0; }

log="$state/sessions/$sid.log"
[ -f "$log" ] || { note "No files recorded yet for this session."; exit 0; }

# Display paths relative to the Claude pane's cwd (else ~-abbreviated).
base="$(tmux display-message -p -t "${sid_pane:-$origin}" '#{pane_current_path}' 2>/dev/null || true)"
[ -n "$base" ] || base="/nonexistent"  # never match, never strip "/"
display_path() {
  case "$1" in
    "$base"/*) printf '%s' "${1#"$base"/}" ;;
    "$HOME"/*) printf '~/%s' "${1#"$HOME"/}" ;;
    *)         printf '%s' "$1" ;;
  esac
}

# Newest first, de-duplicated, existing files only. Lines are
# "<display>\t<absolute path>"; fzf shows field 1, previews/opens field 2.
existing=""
while IFS= read -r f || [ -n "$f" ]; do
  [ -n "$f" ] && [ -e "$f" ] && existing="${existing}$(display_path "$f")"$'\t'"${f}"$'\n'
done < <(tail -r "$log" | awk '!seen[$0]++')
[ -n "$existing" ] || { note "No existing files to show for this session."; exit 0; }

out="$(printf '%s' "$existing" | fzf \
  --prompt='claude files > ' \
  --header='enter: open   ctrl-o: open in new Ghostty window' \
  --expect=ctrl-o \
  --delimiter=$'\t' --with-nth=1 --keep-right \
  --preview 'bat --color=always --style=numbers --line-range=:500 {2} 2>/dev/null || cat {2}' \
  --preview-window='right,60%,border-left')" || exit 0
key="$(printf '%s\n' "$out" | sed -n 1p)"
sel="$(printf '%s\n' "$out" | sed -n 2p)"
sel="${sel#*$'\t'}"
[ -n "$sel" ] || exit 0

# Look up the opener by extension (exact match wins; "*" is the fallback).
ext="$(printf '%s' "${sel##*.}" | tr '[:upper:]' '[:lower:]')"
mode="" cmd="" dmode="" dcmd=""
if [ -f "$conf" ]; then
  while read -r cext cmode ccmd || [ -n "$cext" ]; do
    case "$cext" in ''|'#'*) continue ;; esac
    if [ "$cext" = '*' ]; then dmode="$cmode"; dcmd="$ccmd"; continue; fi
    if [ "$cext" = "$ext" ]; then mode="$cmode"; cmd="$ccmd"; fi
  done < "$conf"
fi
[ -n "$mode" ] || { mode="$dmode"; cmd="$dcmd"; }
[ -n "$mode" ] || { mode="split"; cmd="bat --paging=always"; }
# ctrl-o detaches terminal openers into their own window (GUI apps already are).
[ "$key" = ctrl-o ] && [ "$mode" != gui ] && mode=window

# New Ghostty window (via its AppleScript API) running "<cmd> <file>"; the
# ghostty-run-and-close.sh wrapper closes it when the command exits. Ghostty starts commands with a bare launchd PATH, so
# pass ours (and a few other vars the viewers care about) through.
open_window() {
  local env=() v
  for v in PATH XDG_CONFIG_HOME EDITOR LANG LC_ALL BAT_THEME; do
    [ -n "${!v:-}" ] && env+=("$v=${!v}")
  done
  osascript - "$1" "$2" "${env[@]}" >/dev/null <<'OSA'
on run argv
  set envs to {}
  repeat with i from 3 to count of argv
    set end of envs to item i of argv
  end repeat
  tell application "Ghostty"
    set cfg to new surface configuration
    set command of cfg to item 1 of argv
    set initial working directory of cfg to item 2 of argv
    set environment variables of cfg to envs
    activate
    new window with configuration cfg
  end tell
end run
OSA
}

case "$mode" in
  gui)
    # Non-terminal app; launch detached, no split.
    nohup $cmd "$sel" >/dev/null 2>&1 &
    ;;
  window)
    open_window "$HOME/.config/tmux/ghostty-run-and-close.sh $cmd $(printf '%q' "$sel")" \
      "$(dirname "$sel")" \
      || note "Couldn't open a Ghostty window (Automation permission?)."
    ;;
  *)
    # Full-height left split in the origin's window, matching toggle-side-pane.sh.
    qsel="$(printf '%q' "$sel")"
    newp="$(tmux split-window -fbh -l 40% -c "$(dirname "$sel")" -t "$origin" \
              -P -F '#{pane_id}' "$cmd $qsel" 2>/dev/null)" || exit 0
    [ -n "$newp" ] && tmux select-pane -t "$newp" 2>/dev/null
    ;;
esac
exit 0
