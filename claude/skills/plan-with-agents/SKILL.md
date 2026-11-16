---
name: plan-with-agents
description: Plan a SupplyTrace ticket with a planner agent and an implementer who questions the plan, then one critic pass, and hand the person a review guide with only the calls left for them. Use for "/plan-with-agents STH-123", "plan this ticket with agents", or a replay of a finished ticket's planning.
argument-hint: "STH-<n> [--planner <model>] [--implementer self|<model>] [--out <dir>] [--ticket-file <path>] [--blind]"
---

# plan-with-agents

**Inline.** Runs in the user's conversation and orchestrates agents; it inherits the
session's model and sets none. Prototype, personal skill; not part of the `st-*` family. It
writes a plan and its working files and stops at the person's rulings: plan sign-off,
attaching the plan, claiming the ticket and implementing stay with `st-implement`.

**Goal.** A plan written by a strong planner, questioned by the agent that will implement
it, checked once by a critic, so that the person reviews a short guide with only the calls
that are theirs (behavior, scope, a ticket Decision, anything one-way) instead of running
review rounds.

**Done when** `<out>` holds `plan.md`, `exchange.md`, `critic.md`, `guide.md` and
`metrics.md`; every escalation is in the guide's "Decisions left for you" with the
planner's recommendation; and the reply gives the guide's path, the count of decisions left,
and the metrics line. Rulings, if the person gives them, go back to the planner and land in
`plan.md` and `exchange.md`.

## Arguments

- `STH-<n>`: the ticket. Its snapshot is `.local/ai/plans/STH-<n>/ticket.md` unless
  `--ticket-file` names another. With no snapshot, read the ticket with `get-ticket` and
  write it to `<out>/ticket.md`.
- `--planner <model>`: default `fable`.
- `--implementer self|<model>`: default `self` (this session is the implementer; use it
  when this session will implement). A model alias dispatches a fresh implementer agent;
  pick the ticket's `## Suggested session` model when it names one.
- `--out <dir>`: where everything is written. Default `.local/ai/plans/STH-<n>/`. If
  `<out>/plan.md` already exists, stop and say so: this skill never overwrites a plan.
- `--blind`: a replay. Every agent reads only `<out>` from `.local/ai/`, and the repository
  as checked out on `main`. Off limits: the rest of `.local/ai/` (plans, reviews, hub,
  memory), `~/.claude/` memory, every `STH-*` branch (`git log --all`, `git show` of another
  ref), and every directory under `../supply-trace-be-worktrees/`. This overrides the repo
  rule to reload plans and memory before starting. Copy the ticket snapshot into
  `<out>/ticket.md` first, after checking it carries no plan attachment, claim ruling or
  comment from the original work. The orchestrator relays between agents by file path only,
  never by paraphrase.

## Briefs

Subagents load no `.claude/rules/` and none of this conversation, so every brief carries:

- the ticket file path, and `<out>`;
- the reads in `st-implement`'s Context step (`.claude/skills/st-implement/SKILL.md`,
  "## Context", items 1–6): the ticket, the PRD sections it names, `CONTEXT-MAP.md` and each
  touched `CONTEXT.md`, the ADR index `docs/adr/README.md` and the full text of each ADR
  whose trigger matches, the code, and the existing tests at the seams;
- "Read the `.claude/rules/` files whose `paths` match the files you will touch, and the
  root `CLAUDE.md` and the touched component's `CLAUDE.md`.";
- **standing rulings**: the person's rulings that bear on this ticket and live outside the
  repo (this session's memory feedback entries, rulings recorded in earlier plans or hub
  files), each quoted verbatim from its source (never paraphrased: one added word changes the
  design) with its date and where it's recorded, under "Standing rulings (treat as binding unless the
  ticket overrides one; a conflict is `escalate`)". Under `--blind`, only rulings dated
  before the original claim;
- the `--blind` restriction, when set;
- "Write nothing outside `<out>`. No Notion writes, no commits, no pushes."

## Steps

Agents run at `effort: high` (the planner and the critic must). Before every planner
revision, copy `plan.md` to `<out>/history/plan-<step>.md`, so the guide and the metrics can
show what each exchange changed.

1. **Plan.** Dispatch the planner (Agent, `general-purpose`, `model` = planner) with the
   brief and: write `<out>/plan.md` in the exact template
   `.claude/skills/st-implement/reference/plan-template.md`, with one deliberate change to
   its bar. Instead of "a fresh session could continue", the bar is: an implementer who
   reads this plan and the code will question you, so state intent and decisions plainly,
   leave out what a competent implementer derives from the code (test names past the
   proving test per criterion, line ranges, restated rules that don't shape the design),
   and record every assumption you made. Open the Context section with a short paragraph
   saying what the change is for and its shape. Write each assumption, and each
   contradiction between the ticket and the code, ADRs or rules, to `<out>/exchange.md`
   under `## Planner`, tagged `clarify` or `escalate` like step 2's items; a contradiction
   is always `escalate`. Where an `escalate` item is open, the plan follows the
   recommendation and marks each affected Decision and task `(pending: <item id>)`. Return a
   five-line summary. Keep the planner addressable: later steps continue it with
   SendMessage (load it through ToolSearch first if it's deferred).
2. **Question.** The implementer (this session for `self`, or a fresh Agent on its model
   with the brief) reads the ticket, `plan.md` and the code it touches, as the one who will
   build it. It writes questions to `<out>/exchange.md` under `## Round <m>`, each:
   - `Q<m>.<i>`, the question, the plan text it's about (quoted), and why it would have to
     guess;
   - a tag: `clarify` (the pair can settle it: wording, an interface, a missing detail) or
     `escalate` (the answer changes behavior, scope, a ticket Decision, or is one-way).
   It also lists anything it believes is wrong (a defect), tagged the same way. No questions
   it could answer from the code itself. In round 1 it also answers every planner `clarify`
   item (`P.<i>`) in one line: `agree`, or `disagree: <why>` and retag it `escalate`. An
   assumption it agrees with stays settled by the pair and is listed in the guide for veto.
3. **Answer.** Continue the planner: answer every `clarify` question in `exchange.md` under
   the question, revise `plan.md` to match, and name the change. For an `escalate` item,
   don't decide: write the options and a recommendation. The planner may retag a `clarify`
   as `escalate`, never the reverse.
4. **Repeat** steps 2–3 at most twice more. Later rounds ask only about text the last
   answers changed, or a question not yet settled. Stop when a round has no `clarify`
   questions.
5. **Critic.** A fresh Agent (`general-purpose`, `model: opus`) reviews `plan.md` against
   the ticket with the checks in `.claude/skills/st-review/kinds/plan.md` § Checks, check 7
   read with this skill's bar instead of pick-up-ability, and returns findings in the JSON of
   `.claude/skills/st-review/reference/findings.md`. Write them to `<out>/critic.md`. One
   pass. Continue the planner with the findings: fix every finding whose fix changes no
   behavior, scope or ticket Decision, noting each in `exchange.md` under `## Critic`; turn
   the rest into `escalate` items with options and a recommendation. Then the implementer
   re-reads only what the critic's fixes changed (diff against the last `history/` copy) and
   writes `## Round <m> (after critic)` the same way as step 2; the planner answers as in
   step 3. One round, no more.
6. **Guide.** Run the `review-guide` skill as `plan STH-<n> --dir <out> --out <out>/guide.md`.
7. **Metrics.** Write `<out>/metrics.md`: plan words; questions by round and tag; critic
   findings by check, severity and type (defect, conformance, gap) and how each was settled
   (fixed by the pair, escalated); escalations total, by source (planner, implementer,
   critic); words changed by each revision (from `history/`); agents dispatched with model
   and effort.
8. **Report and rulings.** Reply with the guide path, the number of decisions left, the
   metrics line, and the escalations as a numbered list (one line each, with the
   recommendation). Take the person's rulings; continue the planner to apply them to
   `plan.md` and record each, dated, in `exchange.md` under `## Rulings`. Then one critic
   pass on what the rulings changed (diff against the copy taken before them), with the
   step 5 brief plus "review only the changed text and what it touches; report Important
   findings and Nits on that text only". Its findings go through step 5's disposition;
   anything it escalates comes back to the person. Then re-run step 6 for the final guide.

## Boundaries

- The person rules on every `escalate` item; agents settle only `clarify` items and
  precision fixes, and the guide lists what they settled so it can be vetoed.
- The planner and implementer never change the ticket. A ticket that looks wrong is an
  `escalate` item.
- Never overwrite an existing `plan.md`, and never write into another session's effort
  directory: pass `--out` to a scratch directory when one exists.
