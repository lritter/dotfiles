# extract-entities — Design Spec

**Date:** 2026-06-12
**Status:** Converged after iteration-2 eval (user-approved); installed + packaged
**Location:** Global skill, `~/.claude/skills/extract-entities/` (usable in Claude Code and cowork)

## Revision — 2026-06-12 (after iteration-1 eval feedback)

Reviewing real outputs (Politico tariff article, DoD 1260H PDF, BBC trafficking
story) changed three things from the original brainstorm:

1. **Scope is companies by default.** The brainstorm said "companies + orgs";
   the user's review made clear that government agencies, trade reps, and bare
   countries read as noise. New default: extract **companies only**. Non-company
   organizations (agencies, NGOs, trade associations, ports, universities) are
   included only when the user explicitly asks. Bare countries/nationalities and
   individuals are always out. When scope is ambiguous, the skill leans to
   companies and *offers* the rest; when genuinely unsure what's in scope, it
   asks.
2. **Blocked source → stop, don't substitute.** Try the given URL (WebFetch,
   then curl-with-headers to the *same* URL). If still blocked, do not pull a
   mirror / archive / wire reprint — report a *fetch failure* unmistakably
   (distinct from "no companies found") and ask the user for the text.
3. **Name-encoded locations are grounded.** A place in the entity's own name or
   stated in the text ("Shenzhen DJI" → Shenzhen) counts; the "don't guess"
   rule only bars importing outside knowledge.

The sections below are the original design; where they conflict with the above,
the revision wins.

## Purpose

Extract corporate/organizational entities from a report, news article, or
similar media and produce a CSV with one row per distinct entity. Each row
captures the entity's name, aliases, location, its role in the document, any
concern/wrongdoing the document raises, an extraction confidence, a short
verbatim quote, and the source URL.

## Output contract

One CSV **per source document**. Fixed column order:

| # | column | contents |
|---|--------|----------|
| 1 | `entity_name` | primary extracted name |
| 2 | `entity_type` | `company` / `government_agency` / `ngo` / `trade_association` / `port` / `university` / `other` |
| 3 | `aliases` | alternate names, abbreviations, tickers, former names, native-language names — `;`-separated |
| 4 | `location` | most specific available: city, region, country, or address — `;`-separated if multiple |
| 5 | `role` | neutral relationship in the doc: supplier, manufacturer, buyer, parent, subsidiary, regulator, etc. |
| 6 | `concern_type` | controlled vocabulary tags (see below); `;`-separated; `none` when no wrongdoing implied |
| 7 | `concern_detail` | free-text of the specific allegation; blank if none |
| 8 | `confidence` | `high` / `medium` / `low` |
| 9 | `quote` | short verbatim extract (≤ ~240 chars), copied exactly from the source |
| 10 | `source_url` | URL of the media; blank for local files without a URL |

### Output location & naming

Default: write to the current working directory as `<slug>-entities.csv`,
where `<slug>` is derived from the document title or, failing that, the URL
domain/filename (lowercased, non-alphanumerics → `-`). If the user names a
path or directory, honor it. If the target file already exists, confirm before
overwriting.

### `concern_type` controlled vocabulary

`forced_labor`, `child_labor`, `labor_violation`, `sanctions`,
`environmental`, `corruption`, `financial_misconduct`, `human_rights`,
`safety`, `legal_action`, `other`, `none`.

(Documented authoritatively in `references/schema.md`; this list is the
starting set and may grow there.)

## Architecture

**Approach B — script-assisted serialization.** Claude does all extraction
judgment; a deterministic stdlib-only helper does CSV serialization. This kills
the hand-written-CSV escaping failure mode (commas/quotes/newlines inside
`quote` and `concern_detail`) while keeping the skill portable.

### Layout

```
~/.claude/skills/extract-entities/
  SKILL.md                 # workflow + extraction rules (model instructions)
  scripts/write_csv.py     # stdlib-only serializer: JSON rows -> escaped CSV
  references/
    schema.md              # column definitions + controlled vocabularies
    example.csv            # a sample output row for grounding
  docs/
    2026-06-12-extract-entities-design.md   # this spec
```

### Data flow

1. **Resolve input.**
   - URL → `WebFetch` the page/article.
   - Local file → `Read` (PDFs via page ranges; txt/md/docx directly).
   - Already in conversation context → use that.
2. **Capture `source_url`.** The fetched URL; for local files, ask once or
   leave blank.
3. **Extract.** Claude reads the text and builds an in-memory list of entity
   row objects per the schema + extraction rules.
4. **Serialize.** Claude writes the rows as JSON to a temp file and runs
   `scripts/write_csv.py <rows.json> <out.csv>`. Fallback: if no Python
   runtime, write the CSV directly with the Write tool, escaping carefully.
5. **Report.** N entities found, output path, caveats (fetch issues,
   low-confidence rows, no-entity result).

### Helper contract — `scripts/write_csv.py`

- **Input:** path to a JSON file containing an array of row objects, plus an
  output CSV path. (`python scripts/write_csv.py <rows.json> <out.csv>`)
- **Behavior:** writes header + rows in the fixed column order using
  `csv.writer` (correct escaping). Missing keys → empty cell. Unknown keys →
  ignored with a stderr warning. Empty array → header-only CSV.
- **Constraints:** stdlib only (`csv`, `json`, `sys`, `argparse`). No network,
  no extraction logic, no entity reasoning. Pure serialization.

## Extraction rules (the heart of SKILL.md)

- **One row per distinct entity.** Multiple mentions of the same organization
  collapse into one row: variant spellings → `aliases`, the single most
  informative mention → `quote`, concerns aggregate into `concern_type` /
  `concern_detail`.
- **Entities = organizations only.** Skip individuals (people) unless the name
  *is* a business. In scope: companies, government agencies, NGOs, trade
  associations, ports, universities — typed via `entity_type`.
- **aliases:** abbreviations, tickers, former names, native-language names.
- **location:** most specific available — HQ, or the location the document ties
  to the entity.
- **role:** neutral description of how the entity figures in the document.
- **concern_type:** from the controlled vocabulary; `concern_detail` carries
  the specifics; `none` when the document implies no wrongdoing.
- **confidence:**
  - `high` — explicitly named organization, clearly a distinct entity.
  - `medium` — named but ambiguous or partial.
  - `low` — inferred, or possibly a product/brand/person rather than an org.
- **quote:** short verbatim extract (≤ ~240 chars), copied exactly. No
  paraphrasing.
- **Never fabricate.** Absent info = blank cell, not a guess. No invented
  locations, concerns, or aliases.

## Error handling / edge cases

- **No entities found:** write a header-only CSV and report it. Do not fail
  silently.
- **Fetch fails:** report the failure; offer to accept pasted text or a local
  file instead. No fabricated rows.
- **Long documents:** reason in chunks but emit one consolidated CSV; dedupe
  entities across chunks.
- **Ambiguous person vs. company:** default to skipping individuals; include
  only when the name denotes a business; mark `low` confidence if unsure.

## Testing

- **Helper (deterministic) — real tests:**
  - commas, double-quotes, and newlines inside `quote` / `concern_detail`
  - missing keys → empty cells
  - unknown keys → ignored (with warning)
  - empty array → header-only file
  - column order + header correctness
- **Extraction (model judgment):** one fixture article run end-to-end, output
  eyeballed for correctness. Not asserted in automated tests.

## Out of scope (YAGNI)

- Appending to a master/accumulating CSV (chose one-CSV-per-document).
- Fetching/PDF-parsing/dedup inside the helper (kept in Claude's hands).
- Entity resolution against any external database.
