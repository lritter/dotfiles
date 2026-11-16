---
name: review-guide
description: Write a human reviewer's guide to a SupplyTrace plan or code change after the agent review rounds, so a person can do the final review without reconstructing context. Use for "/review-guide", "write a review guide for PR 682", "guide me through the STH-1568 plan before I sign off".
argument-hint: "<code|plan> <STH-n | PR number> [--dir <plan-with-agents dir>] [--out <path>]"
context: fork
model: opus
effort: high
---

# review-guide

**Forkable.** Takes its target as arguments, reads files, writes one markdown guide, and
returns its path. It never asks the user anything and never changes the plan, the code, the
review logs, a ticket or a PR. Prototype, personal skill; not part of the `st-*` family.

**Goal.** A person who wasn't in the work (a cold reader such as a second engineer), or who
was but has lost the thread, can open the guide and do the final review: know what the
change is for, what they are being asked to decide, where to look, and what the agents
already checked or settled. Every sentence is readable without opening another file; files
are where the reader goes to verify, not to understand.

**Done when** the guide is written, every section below is present (a section with nothing
to say says so in one line), the self-check passes, and the reply gives the path plus a
three-line summary (what it is, how many decisions are left for the reader, the one thing to
look at first).

## Inputs

Resolve the target (repository root is the working directory):

- **A PR number:** `gh pr view <n> --json number,title,url,headRefName,headRefOid,body,state`;
  the ticket id is the `STH-<n>` prefix of the branch. Kind is `code`.
- **An STH id:** the effort directory is `.local/ai/plans/STH-<n>/`.

Read, for both kinds: `ticket.md` (the ticket snapshot), `plan.md`. With `--dir`, read
these from `<dir>` and nothing from the ticket's effort directory.

- **plan:** the latest `reviews/plan-<k>/` review: every `round-*.md` (findings are a JSON
  block, rulings follow it) and `round-*/reference.md`.
- **plan with `--dir <dir>`** (from `plan-with-agents`): `<dir>/ticket.md`, `plan.md`,
  `exchange.md` (implementer questions and planner answers, critic dispositions, rulings)
  and `critic.md` instead of the effort directory. Unresolved `escalate` items are
  "Decisions left for you", tagged `[escalated]` with the planner's options and
  recommendation; settled `clarify` items and the critic fixes are "What the agents changed
  along the way"; the critic's `declined` lines go in "What no agent judged".
- **code:** the latest `reviews/code-<k>/`: every `round-*.md`, and the last round's
  snapshot (`round-<m>/diff.patch`, `log.txt`, `evidence.md`). If a PR exists, compare its
  `headRefOid` with the first commit in the last round's `log.txt`; when the PR has commits
  the last round didn't see, use `gh pr diff <n>` as the diff and say in the guide which
  commits no agent reviewed. Read the PR body.

Read code at `file:line` as needed to quote it. The guide is about the change as it stands
now, not as round 1 saw it.

## The guide

Write it to `--out` if given, else `<effort dir>/guides/<kind>-<k>.md`. Sections, in order:

1. **Title and what was reviewed:** `# Review guide: <ticket title> (<kind>, STH-<n>[, PR #<n>])`,
   then one line: date and how many agent rounds ran. Then what was reviewed: for code, the
   head commit as `` `<short sha>` <subject> `` and the commit count on its merge-base; for a
   plan, the plan file's last-modified date and the round that last read it.
2. **What this is for** (3–6 sentences, plain language). The problem, who sees what
   differently once it ships, and the shape of the change. No ids, no file names unless the
   file is the point.
3. **Where to look.** Two parts, together:
   - **How to read it:** an order through the diff or plan: groups of files by purpose, the
     two or three places that carry the logic (read closely), and what's mechanical (skim:
     renames, fixtures, generated files, snapshots). Approximate sizes so the reader can
     budget.
   - **What no agent judged:** each round's `declined` lines, findings left at Speculative,
     checks that need a running system (staging, production data, BigQuery), and the After
     merge steps that carry risk. Each line traces to its source.
4. **Decisions left for you.** Open with one line saying what this list is: what still
   needs the reader's call after the agent review rounds. Number the items, and tag each
   with where it came from: `[open finding]` (a finding with no ruling yet), `[one-way]`
   (an effect that's hard to reverse: migration, data rewrite, deploy order, public API
   shape), `[ticket asks]` (something the ticket said a person confirms), or `[escalated]` (an item
   `plan-with-agents` escalated). For each:
   - the question in one sentence;
   - the quoted code or plan text it's about (a short excerpt, with `file:line`);
   - what happens under each option, and the recommendation with its reason.
   If nothing is left, say "Nothing; this is a read-through" and why.
5. **What the agents changed along the way.** From the round rulings: fixes that changed
   behavior, scope or a test's meaning, each in one or two plain sentences with where it
   landed. Then precision fixes (naming, docs, wording) as a count and one line of examples.
   Anything ticketed instead of fixed, with its ticket id and title.
6. **Already checked.** What the reviewers verified and found fine, from the verdicts and
   the last round, in a few bullets. This is what the reader can skip.
7. **Terms.** Only domain terms a cold reader needs, each defined in a line (use the
   definitions in the relevant `CONTEXT.md`).

## How to write it

- **Self-contained.** Every finding, decision or id is restated in words where it's used.
  An internal id (`F3`, `STD-1`, `AC2`, `Decision 4`, `T7`, `R2`) may appear only in
  parentheses after its plain description, for traceability.
- **Quote, then explain.** Show the line, then say what it does. Don't paraphrase code the
  reader is being asked to judge.
- **Everything traces.** A claim about what an agent found, checked or declined cites the
  round it came from (`round 2`), so it can be checked.
- **Short.** Aim for one to two printed pages; past three, cut section 7 first, then 5's
  precision list.
- **Plain American English**, domain terms from the glossary, no emojis. Refer to people by
  role ("the engineer", "the reviewer"); where a pronoun is needed, use they/them.

## Self-check before returning

- Grep the guide for `\bF\d+\b`, `STD-\d`, `SPEC-\d`, `\bAC\d`, `Decision \d`, `\bT\d+\b`,
  `\bR\d\b`: each hit must sit in parentheses after a plain description.
- Every "Decisions left for you" item has a source tag, a quote, the options and a recommendation.
- Every "What no agent judged" line names its source round or step.
- No local paths outside `file:line` citations into the repository.
