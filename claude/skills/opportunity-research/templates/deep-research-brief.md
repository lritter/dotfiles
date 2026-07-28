# Deep Research Brief: [Topic]

> **Instructions for the user:** Paste everything below this line into a new claude.ai chat with Deep Research enabled. When the report finishes, save it as `research/<topic>/03-deep-research-report.md` in the repo and tell Claude Code it's ready.

---

## Context

I'm exploring product opportunities for **[product name]**, a **[one-sentence description: what it is, who it serves, what data/capabilities it works with]**.

I want to understand the external landscape around **[topic]** so I can map our capabilities to real-world needs. I'm in opportunity-discovery mode, not validating a specific product — so breadth matters as much as depth.

## What we already have

The following capabilities are already built or substantially built. Use these as the grounding for what's plausibly buildable on top of our foundation. Do **not** propose ideas that ignore this foundation — the point is to find opportunities that leverage it.

[Paste the relevant sections of `01-capabilities.md` here — Summary, Data foundation, Analytical capabilities, Integrations, Surface area, and Half-built / dormant. Trim aggressively; Deep Research doesn't need file citations.]

## What I want you to research

Please investigate the following areas. Each is a separate research thread — feel free to structure the final report by thread.

### 1. [Research thread — e.g. "Regulatory landscape for human rights supply chain compliance"]

[1-3 specific questions per thread. Concrete. Examples:]

- What major regulations exist in this space, globally? For each: who is covered, what specifically must they do, what evidence/documentation is required to demonstrate compliance, penalties, and current enforcement posture.
- Which regulations are actively being enforced vs. on the books but dormant?
- What changes are expected in the next 12-24 months?

### 2. [Research thread — e.g. "Buyer landscape"]

- Who within target organizations owns the budget for this kind of compliance tooling? What are their titles, what do they care about, what triggers a purchase?
- What is the typical buying process — RFP, direct sales, procurement-led?
- What price points do existing solutions command (range, by tier)?

### 3. [Research thread — e.g. "Competitive landscape"]

- Who else sells solutions in this space? For each major player: what they sell, who their buyers are, their core differentiator, recent funding/M&A activity, any known weaknesses or customer complaints.
- Where are the obvious gaps in current offerings?

### 4. [Research thread — e.g. "Adjacent applications"]

- Where else have capabilities like ours been applied — what other problems do similar tools solve in adjacent industries?

[Add or remove threads as needed for the topic.]

## What I do NOT want

- Generic AI/ML capability hand-waving — be specific about what *exists* in the market, not what *could* exist.
- Marketing-speak summaries of vendor websites. Treat vendor self-descriptions skeptically; cross-check against customer reviews, news coverage, court filings, regulator publications, etc.
- Ranking or recommendations. I'll do my own evaluation.
- Investment advice or financial projections.

## Source quality preferences

In rough order of preference:
1. **Primary sources** — actual regulatory text, government enforcement publications, court filings, SEC filings, company financial disclosures.
2. **Trade press and specialist reporting** — industry-specific publications that cover this space regularly.
3. **Consultancy / analyst reports** — useful for market sizing, but treat their framing skeptically.
4. **Vendor websites** — only for understanding vendor positioning, not for evaluating their claims.

If you find conflicts between sources, surface them rather than averaging them out.

## Output format

Please structure the final report as:

```
# [Topic] — Deep Research Report

## Executive summary
3-5 paragraphs hitting the most important findings across all threads.

## Thread 1: [name]
[Detailed findings, with inline citations.]

## Thread 2: [name]
...

## Open questions
Things you couldn't answer well, or where sources conflict significantly. This helps me decide whether to do a second round.

## Sources
Full source list, organized by thread.
```

Be thorough. I'd rather have a long, well-sourced report than a short one that misses things.
