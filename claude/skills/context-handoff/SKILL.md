---
name: context-handoff
description: Use when context is running low and work remains, or when user wants to continue a session in a fresh context via /context-handoff
---

# Context Handoff

Generate a continuation prompt to preserve session context when starting fresh.

## When to Use

**Proactive (Claude-initiated):**
- After completing a significant task when context appears constrained
- When non-trivial work remains and conversation has been long
- Use judgment based on: conversation length, remaining todos, complexity ahead

**On-demand (User-initiated):**
- User runs `/context-handoff`
- Always offer to generate prompt regardless of context level

## Flow

```
User message / task completion
         │
         ▼
┌─────────────────────────────┐
│ Context low + work remains? │──no──▶ Continue normally
└─────────────────────────────┘
         │ yes
         ▼
┌─────────────────────────────┐
│ Ask: "Generate handoff      │──no──▶ Continue normally
│ prompt for new session?"    │
└─────────────────────────────┘
         │ yes
         ▼
┌─────────────────────────────┐
│ Generate continuation prompt│
│ Show to user for review     │
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ Ask: Confirm / Edit / Cancel│
└─────────────────────────────┘
         │ confirm
         ▼
┌─────────────────────────────┐
│ Copy to clipboard (pbcopy)  │
│ Tell user: /clear then paste│
└─────────────────────────────┘
```

## Continuation Prompt Structure

Adapt to what's relevant. Not all sections required.

```markdown
## Goal
[Original objective - what we're trying to accomplish]

## Completed
- [Key accomplishments from this session]
- [Important milestones reached]

## Current State
[Where things stand - branch, test status, blockers]

## Remaining Work
- [What's left to do]
- [Active todos if using task list]

## Key Decisions Made
- [Important choices and rationale that shouldn't be re-debated]

## Key Files
- `path/to/planning/docs` - what it contains
- `path/to/implementation` - what it contains

## Notes
[Gotchas, warnings, context that would otherwise be lost]
```

## Executing the Handoff

After user confirms the prompt, run this to save and automatically restart:

```bash
# Save the prompt
HANDOFF_FILE="$HOME/.claude/handoff-prompts/pane-${TMUX_PANE#%}.md"

cat << 'EOF' > "$HANDOFF_FILE"
[generated prompt content]
EOF

# Also copy to clipboard as backup
cat "$HANDOFF_FILE" | pbcopy

# Trigger the handoff with delay (so this script exits and Claude returns to input loop)
~/.claude/skills/context-handoff/bin/run-handoff.sh --clear --delay 0.5 "$HANDOFF_FILE"
```

This will:
1. Save the prompt to a pane-specific file
2. Copy to clipboard as backup
3. Schedule `/clear` to be sent in 0.5s (after this Bash command exits)
4. Schedule the continuation prompt to be sent after `/clear`

**If automatic handoff fails:** The prompt is in your clipboard - just `/clear` and paste manually.

## Judgment Guidelines

**Suggest handoff when:**
- Conversation has 20+ back-and-forth exchanges
- Multiple complex tool operations have occurred
- Remaining work involves exploration or multi-file changes
- User seems to be starting a new phase of work

**Don't interrupt for:**
- Simple follow-up questions
- Quick fixes or small tasks
- When user is in flow on focused work

**When in doubt:** Ask rather than interrupt. A simple "Context is getting full - want me to prepare a handoff prompt?" is fine.
