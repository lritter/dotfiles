#!/usr/bin/env bash
#
# SessionEnd hook — copies the completed JSONL transcript into the KB's
# raw/sessions/<source>/ directory so the Cowork scheduled ingest can
# reach it without symlink resolution.
#
# Expects a JSON object on stdin with at least:
#   { "session_id": "...", "transcript_path": "/abs/path/to/<uuid>.jsonl" }
#
# Install by adding to both Claude config roots' settings.json:
#   "hooks": { "SessionEnd": [{ "matcher": "", "hooks": [{ "type": "command",
#     "command": "/Users/lritter/src/dotfiles/claude/bin/copy-session-log" }] }] }

set -euo pipefail

KB_ROOT="/Users/lritter/SupplyTrace/src/claude-code-session-kb"
RAW_DIR="$KB_ROOT/raw/sessions"

# --- Read hook payload from stdin ---
INPUT=$(cat)
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty')
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')

[ -z "$TRANSCRIPT" ] && exit 0
[ -f "$TRANSCRIPT" ] || exit 0

# --- Resolve the transcript's containing directory (canonical) ---
TRANSCRIPT_DIR=$(cd "$(dirname "$TRANSCRIPT")" && pwd -P)

# --- Match against each source's symlink target ---
for SOURCE_LINK in "$RAW_DIR"/*/; do
    SOURCE_NAME=$(basename "$SOURCE_LINK")
    LINK_TARGET=$(readlink -f "$RAW_DIR/$SOURCE_NAME" 2>/dev/null) || continue

    if [ "$TRANSCRIPT_DIR" = "$LINK_TARGET" ]; then
        DEST="$RAW_DIR/$SOURCE_NAME"
        DEST_FILE="$DEST/${SESSION_ID}.jsonl"

        # Copy (overwrite if exists — the latest version is always more complete)
        cp "$TRANSCRIPT" "$DEST_FILE"
        exit 0
    fi
done

# No matching source — session is from an untracked project, ignore.
exit 0