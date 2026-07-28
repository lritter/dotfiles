---
name: opportunity-research
description: Discover and evaluate potential product or feature opportunities for a software product by grounding the search in the actual codebase, then expanding outward through external research. Use whenever the user wants to explore "what could we build", "what opportunities exist in X market", "what products could we offer around Y regulation", or any variant of opportunity discovery / market sizing / adjacent-product brainstorming for a software product they own. Also use when the user explicitly asks to prepare a handoff to web-based Deep Research, or to ingest a Deep Research report back into a codebase-aware analysis. This skill is the right choice even if the request doesn't use the word "opportunity" — anything in the shape of "we have capability X, what could we sell / build / pursue" is in scope.
---

# Opportunity Research

A structured workflow for discovering product opportunities that sit at the intersection of (a) what a codebase can actually do today, (b) what an external market needs, and (c) what's feasible to build. Designed to round-trip between Claude Code (which can read the code) and claude.ai Deep Research (which is better at external market and regulatory research), then synthesize back in Claude Code.

The output is a structured opportunity matrix the user can evaluate against their own criteria — *not* a recommendation. The skill is deliberately agnostic about which opportunities are "best"; ranking is the user's job.

## When to use this

Trigger on requests like:

- "What products could we build around [domain]?"
- "What opportunities exist for us in [market/regulation/trend]?"
- "I want to research possible offerings related to [X]."
- "Help me think through what we could sell to [buyer persona]."
- "Prepare a Deep Research handoff for [topic]."
- "I've got a Deep Research report back — let's synthesize."

Do **not** use this skill for: (a) evaluating a single specific product idea the user has already settled on — that's a different workflow (PRD / spec writing), (b) pure market research with no product angle, (c) competitive teardowns of a named competitor.

## The workflow at a glance

Four phases. The user can enter at any phase if prior artifacts already exist.

1. **Capability inventory** — read the codebase, produce a structured inventory of what the product actually does today. *Claude Code only — this is the unique value.*
2. **Deep Research handoff** — produce a briefing document the user pastes into claude.ai's Deep Research feature. Defines the external research questions grounded in the capability inventory.
3. **Synthesis** — ingest the Deep Research output, cross it with the capability inventory, produce an opportunity matrix.
4. **(Optional) Iteration** — based on user feedback on the matrix, drill deeper into specific opportunities, or kick off another Deep Research round on narrower questions.

All artifacts live in `research/<topic-slug>/` at the repo root. Slug is kebab-case, derived from the topic (e.g. `human-rights-compliance`, `pricing-optimization`).

## Phase 1: Capability inventory

### Goal

Produce `research/<topic>/01-capabilities.md` — a grounded, file-cited inventory of what the codebase can do, scoped to what's plausibly relevant to the user's topic.

### How to do it

1. **Confirm scope with the user.** Ask one question if the topic is ambiguous: "Should I scope this to capabilities relevant to [topic], or do a full system inventory?" Default to scoped — full inventories balloon.

2. **Survey the code.** Use Read, Grep, and Glob. Do not run the actual application. Look for:
   - **Data sources & schemas** — what entities exist, what fields, what relationships. Cite specific schema files / migrations / models.
   - **Analytical primitives** — what queries / aggregations / transformations are implemented. Note which are cheap (indexed, materialized) vs expensive (full scans).
   - **Pipeline stages** — what gets computed, in what order, how often. ETL, batch jobs, real-time paths.
   - **External integrations** — what third-party data sources, APIs, services are wired up. Auth methods, rate limits if documented.
   - **Surface area** — what's exposed to users via API/UI vs internal-only. Auth model, multi-tenancy story.
   - **Half-built / dormant capabilities** — code that exists but isn't shipped or isn't exposed. These are often the most interesting because they're cheap to productize. Look for feature flags, commented-out routes, abandoned branches mentioned in TODOs.

3. **Write the inventory.** Structure:

   ```markdown
   # Capability Inventory: [topic scope]

   Generated: YYYY-MM-DD
   Repo: [name]

   ## Summary
   2-3 sentences. What this product fundamentally does, in plain language.

   ## Data foundation
   - What entities/records exist (with counts/scale if findable)
   - Key relationships and resolution logic
   - Source citations: `path/to/file.py:L42`

   ## Analytical capabilities
   For each: name, what it computes, cost profile, surface (API/internal/dormant), file citation.

   ## Integrations
   What's wired up, what it's used for.

   ## Surface area
   What customers can actually access today vs what's internal.

   ## Half-built / dormant
   Things that exist in code but aren't fully shipped. These are leverage points.

   ## Notable gaps
   Things that would be obviously useful but aren't built. Don't speculate widely — only call out gaps that are obviously absent.
   ```

4. **Be skeptical of the marketing version.** Do not describe what the product *claims* to do — describe what the code *does*. If something is in a README but not in code, flag it as "documented but not found in code." If something is in code but only in a test fixture or seed file, say so.

5. **Show the inventory to the user and ask for corrections** before moving on. The user knows things the code doesn't say. Common corrections: "that's deprecated", "that only works for one customer", "we built that but it's broken in prod."

## Phase 2: Deep Research handoff

### Goal

Produce `research/<topic>/02-deep-research-brief.md` — a self-contained document the user pastes into claude.ai's Deep Research. Must include enough context that Deep Research can do its job without seeing the codebase.

### How to do it

1. **Identify the external research questions.** Based on the topic and the capability inventory, what does Deep Research need to figure out that we can't figure out from the code? Typical buckets:

   - **Market / demand structure** — who buys things in this space, what they pay, what triggers purchase, what the budget owner cares about.
   - **Regulatory / policy landscape** — what regs exist, who's covered, what evidence is required, enforcement posture, upcoming changes.
   - **Competitive landscape** — who else sells into this space, what they sell, pricing if findable, positioning, recent funding/M&A.
   - **Adjacent use cases** — what other problems this kind of capability has been applied to elsewhere.

   Pick the buckets that fit the user's topic. Not all topics need all buckets.

2. **Write the brief.** Use the template at `templates/deep-research-brief.md`. The template has placeholders for the capability summary (paste in the relevant bits from phase 1 — do not include the full inventory, just what Deep Research needs), the specific research questions, the desired output structure, and source-quality guidance.

3. **Tell the user how to use it.** Give them concrete instructions:

   > "Open claude.ai, start a new chat, enable Deep Research, paste in the contents of `research/<topic>/02-deep-research-brief.md`, and let it run. When it produces the final report, save it as `research/<topic>/03-deep-research-report.md` in this repo. Then come back here and tell me it's ready."

4. **Do not try to invoke Deep Research from Claude Code.** It's not exposed as a tool. The handoff is manual by design.

## Phase 3: Synthesis

### Goal

Produce `research/<topic>/04-opportunity-matrix.md` — a structured matrix mapping capabilities × external findings → candidate opportunities. The user will evaluate these against their own criteria (mission alignment, impact, cost, revenue, etc.). The skill does **not** rank or recommend.

### How to do it

1. **Verify both inputs exist.** Read `01-capabilities.md` and `03-deep-research-report.md`. If the Deep Research report is missing, stop and ask the user to produce it (or proceed without it if they explicitly say to — quality will suffer).

2. **Identify candidate opportunities.** For each external need / market gap / regulatory requirement Deep Research surfaced, ask: which existing capabilities make this addressable? Be specific about what would have to be true.

   Generate opportunities at three levels of build effort:
   - **Repackaging** — existing capability, repositioned or surfaced differently. Cheapest.
   - **Extension** — existing capability + meaningful new work on top.
   - **New build** — substantially new system, but plausibly within reach given the foundation.

   Aim for breadth, not depth, in this pass. 10-20 candidates is reasonable. Bad ideas are fine here — they help calibrate the good ones. Don't pre-filter.

3. **Structure the matrix.** For each candidate:

   ```markdown
   ### [Opportunity name]

   - **Build level:** repackaging / extension / new build
   - **Capabilities leveraged:** [bulleted list, citing inventory items]
   - **External need addressed:** [what Deep Research found that this responds to]
   - **Plausible buyer:** [role, company type]
   - **What we'd need to build:** [concrete, scoped]
   - **What we don't yet know:** [open questions — fuel for phase 4]
   - **Known competitors:** [from Deep Research, if any]
   - **Why this might be wrong:** [one honest sentence about the weakest assumption]
   ```

   The "why this might be wrong" line is important. Without it the matrix reads as a pitch deck. With it, the user can see where to apply pressure.

4. **No rankings, no stars, no "top picks".** The user has explicit evaluation criteria (mission alignment, impact, cost, revenue) that the model can't apply well. Leave the ranking to them. If the user asks for a recommendation anyway, give one, but also remind them of this caveat.

5. **Conclude with the open questions.** A short section at the end listing the things across all candidates that Deep Research didn't answer well and that a second round could clarify. This sets up phase 4.

## Phase 4 (optional): Iteration

If the user wants to drill into specific opportunities or fill open questions, treat each iteration as a mini phase-2 + phase-3 loop on a narrower scope. Naming convention: `research/<topic>/05-deep-research-brief-<round>.md`, `06-deep-research-report-<round>.md`, `07-opportunity-matrix-<round>.md`, etc.

## Working principles

- **Cite files for every capability claim.** "We have entity resolution" is useless. "Entity resolution via `pipelines/entity_resolution/resolver.py`, GLEIF-backed, blocks freight forwarders via the `ssl_or_ff` field" is useful.
- **Distinguish "in code" from "in prod" from "in marketing".** All three drift apart.
- **Don't be a hype machine.** The user has explicitly asked for honest, brutal-truth answers in their preferences. Apply it here: if an opportunity is obviously a stretch, say so in the "why this might be wrong" line.
- **Don't pad the matrix with junk just to hit a target count.** If 6 real opportunities emerge, 6 is the answer.
- **The user is the decider.** This skill produces structured inputs to a decision, not the decision.

## Common pitfalls

- **Inferring capabilities from variable names.** If a class is called `SanctionsScreener` but the only method returns `True`, that's not a capability.
- **Treating the Deep Research output as ground truth.** It's a research assistant, not an oracle. Cross-check anything load-bearing.
- **Letting the matrix get abstract.** "AI-powered insights" is not an opportunity. "A monthly report customers receive listing their suppliers newly added to the UFLPA Entity List, generated by joining their import data with the published list" is.
- **Skipping the user check after phase 1.** The inventory will be wrong in subtle ways. Catching this before phase 2 saves a Deep Research round.

## Files

- `templates/deep-research-brief.md` — template for the Phase 2 handoff document. Read it when entering Phase 2.
