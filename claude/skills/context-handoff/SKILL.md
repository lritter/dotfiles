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
│ "Ready to proceed?"         │──edit──▶ (loop back)
│ (prose, allows edits)       │──cancel─▶ Abort
└─────────────────────────────┘
         │ confirm
         ▼
┌─────────────────────────────┐
│ "Run automatically?"        │
│ (AskUserQuestion)           │
└─────────────────────────────┘
         │
    ┌────┴────┐
    ▼         ▼
  auto      manual
    │         │
    ▼         ▼
┌─────────┐ ┌─────────────────┐
│ /clear  │ │ /clear          │
│ + send  │ │ + buffer only   │
│ + Enter │ │ (user reviews)  │
└─────────┘ └─────────────────┘
```

## Before Generating the Prompt

Check for existing planning artifacts that the next session should reference rather than duplicate:

1. **Plan files** — Look for `.local/ai/plans/<ticket-id>/` (e.g., `.local/ai/plans/STH-445/plan.md`). If a plan exists, the handoff should point to it and note which step you're on, rather than re-listing all remaining work.
2. **Memory files** — Check `.local/ai/memory/` for relevant cross-session learnings that were captured during this session.
3. **Todo lists** — If you used TodoWrite during the session, summarize the current state (what's done, what's in-progress, what's remaining) but keep it brief since the next session can re-read the plan.

4. **Session anchor documents** — Scan the conversation for documents the user explicitly asked you to read or reference as framing context — specs, design docs, architecture references, external links, etc. These should go under Key Files in the handoff so the next session knows to load them too. The distinction: if the user said "read this" or "here's the spec" or "use this as reference," it's an anchor document. If you read a file as part of investigating a bug or implementing a feature (test output, log files, intermediate script results), it's a working artifact and generally doesn't need to be in the handoff.

The goal is to make the handoff prompt a **routing document** — it tells the next session where to look and what state things are in, rather than trying to be a complete copy of everything.

## Continuation Prompt Structure

Adapt to what's relevant. Not all sections required. Keep it tight — if a plan file already covers the details, reference it instead of restating.

```markdown
## Goal

[Original objective - what we're trying to accomplish]

## Plan

Read `.local/ai/plans/<ticket-id>/plan.md` for the full implementation plan. Currently on step N.
(Omit this section if no plan file exists.)

## Completed

- [Key accomplishments from this session]
- [Important milestones reached]

## Current State

[Where things stand - branch, test status, blockers]

## Remaining Work

- [What's left to do — keep brief if plan file has details]

## Key Decisions Made

- [Important choices and rationale that shouldn't be re-debated]

## Key Files

- `.local/ai/plans/<ticket-id>/plan.md` - implementation plan (step N of M)
- `path/to/implementation` - what it contains

## Notes

[Gotchas, warnings, context that would otherwise be lost]
```

## Executing the Handoff

After generating the prompt:

1. **Show the prompt** in a markdown code block
2. **Ask "Ready to proceed?"** (prose) - user can:
   - Confirm ("looks good", "yes", Enter)
   - Request edits ("change X to Y", "add Z")
   - Cancel
3. **Ask "Run automatically?"** (AskUserQuestion) with options:
   - "Yes, auto-run" (default) - submits immediately after /clear
   - "No, let me review" - leaves prompt in buffer for editing
4. **Execute silently** - don't show the shell commands to the user
5. **Confirm** what happened:
   - Auto-run: "Handoff sent. The new session will start in a moment."
   - Manual: "Prompt is in your input buffer. Review/edit, then press Enter."

**If automatic handoff fails:** The prompt is also copied to clipboard - just `/clear` and paste manually.

## Implementation

**Step 1: Choose a unique filename** to avoid collisions with other sessions. Use format: `/tmp/claude-handoffs/handoff-TIMESTAMP-RANDOM.md` where TIMESTAMP is current epoch seconds and RANDOM is 4 hex chars (e.g., `handoff-1706644800-a3f2.md`).

**Step 2: Write the prompt** using the Write tool directly (no Bash needed):
```
Write tool → /tmp/claude-handoffs/handoff-1706644800-a3f2.md
Content: the markdown handoff prompt
```

**Step 3: Execute the handoff** via Bash (don't show command to user):
```bash
# Auto-send (default)
~/.claude/skills/context-handoff/bin/run-handoff.sh --clear --delay 0.5 \
  /tmp/claude-handoffs/handoff-1706644800-a3f2.md

# Or manual review
~/.claude/skills/context-handoff/bin/run-handoff.sh --clear --delay 0.5 --no-auto-send \
  /tmp/claude-handoffs/handoff-1706644800-a3f2.md
```

**Why this pattern:** Using the Write tool for file creation avoids permission prompts. Only the run-handoff.sh script needs Bash, with a simple permission pattern like `Bash(~/.claude/skills/context-handoff/bin/*)`.

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
