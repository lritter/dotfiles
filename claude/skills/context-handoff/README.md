# Context Handoff Skill

This skill enables context preservation across Claude Code sessions by generating continuation prompts and injecting them into new sessions.

## Primary Approach: tmux Send-Keys

The recommended approach uses tmux to inject prompts into the input buffer, giving the user visibility and control. See `SKILL.md` for usage.

## Alternative: Hooks-Based Approach (Not Recommended)

This directory contains an experimental hooks-based implementation that silently injects handoff prompts after `/clear`. While functional, it has UX drawbacks:

- No visibility into what context was injected
- No opportunity to review or edit the prompt
- Blank screen gives no indication a handoff occurred

### How It Works

1. When generating a handoff, `write-handoff-prompt.sh` saves the prompt to a pane-specific file
2. User runs `/clear`
3. SessionStart hook (`hooks/session-start.sh`) detects the pending prompt
4. Hook outputs JSON with `additionalContext` containing the handoff
5. Claude Code injects this into the new session's system context

### Files

```
hooks/
  session-start.sh   # Hook script that checks for pending handoffs
  hooks.json         # Example hooks configuration
```

### Setup

To enable (not recommended), add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "clear",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/context-handoff/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook Output Format

The hook outputs JSON that Claude Code interprets:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<context-handoff>\n...\n</context-handoff>"
  }
}
```

### Why tmux is Preferred

| Aspect | tmux | Hooks |
|--------|------|-------|
| Visibility | Prompt in input buffer | Silent injection |
| Editability | Can modify before sending | No opportunity |
| User awareness | Clear something is pending | Blank screen |
| Timing | Deterministic | Deterministic |
| Complexity | Medium | Low |

The tmux approach trades slightly more complexity for significantly better UX.

### Potential Hybrid Approach

A future improvement could use hooks for timing (fire after `/clear`) but tmux for delivery (send to input buffer). This would give:
- Deterministic timing from hooks
- Visibility from tmux
- Optional auto-send via sentinel in prompt file

This is documented here for future reference but not currently implemented.
