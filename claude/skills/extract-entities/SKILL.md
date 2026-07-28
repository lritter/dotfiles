---
name: extract-entities
description: Use when the user wants to pull the companies or organizations mentioned in a document into a structured CSV — from a news article, report, investigation, press release, PDF, or web page (by URL or local file). Produces one row per distinct entity with its name, aliases, location, role in the document, any concern/wrongdoing it's tied to (sanctions, forced labor, environmental, corruption, etc.), an extraction confidence, a supporting verbatim quote, and the source URL. Trigger whenever the user says things like "extract the companies from this article", "who are the entities/organizations in this report", "pull out every supplier mentioned", "list the firms named in this PDF/URL", or anything in that shape — even if they don't say "CSV" or "entity extraction" explicitly. Especially relevant for supply-chain, sanctions, and human-rights reporting where the entities and their alleged wrongdoing both matter.
---

# Extract Entities

Extract corporate and organizational entities from a document and write a CSV
with one row per distinct entity. The output is meant to be a clean, reviewable
dataset: who is named, what they are, where they are, how they figure in the
story, and — crucially — whether the document ties them to any wrongdoing.

The hard part is judgment: deciding what's a real distinct organization,
merging the five ways an article spells "Xinjiang Production and Construction
Corps" into one row, and separating a neutral role ("supplier") from a concern
("accused of using forced labor"). That judgment is your job. Serializing the
result into a valid CSV is a solved problem — hand it to the bundled script so
commas and quotes inside the text never corrupt the file.

## Workflow

### 1. Get the source text

- **Web page (HTML)** → fetch it with `WebFetch`. The URL becomes `source_url`
  for every row.
- **PDF by URL** → `WebFetch` mangles PDFs, so download it first
  (`curl -sL <url> -o /tmp/doc.pdf`) and then `Read` it by page range (`pages`),
  several pages at a time for long documents. The original URL is still
  `source_url`. (Many official reports, sanctions lists, and filings are PDFs —
  this is a common case, not an edge case.)
- **Local file** → read it with `Read`. PDFs: read by page range (`pages`). For
  a local file there is usually no URL — ask the user once if they have a
  canonical URL for the media, and leave `source_url` blank if not.
- **Already in the conversation** (pasted text, an attached file you've already
  read) → work from what's present. Confirm the `source_url` with the user if
  it isn't obvious.

**If you can't get the source, stop — don't substitute.** Try the URL the user
gave you: `WebFetch` first, and if that's blocked, `curl` the *same* URL with
browser-like headers (a real `User-Agent`, `Accept`, and a matching `Referer` —
several sites, including the DoD and BBC examples, serve fine to `curl` but block
`WebFetch`). If the canonical URL is *still* blocked (e.g. a Cloudflare challenge
page), do **not** go hunting for the article on mirrors, web archives,
reader-proxies, or a wire-service reprint — a different copy may not match what
the user pointed you at. Stop and tell the user plainly that the **fetch failed**,
and ask them to paste the text or hand you a downloaded file.

Make this unmistakable: a fetch failure is *not* the same as "the document named
no companies." Don't let an empty CSV imply the latter — if you couldn't read the
source, say so in those words, and don't assert anything about what the document
contains. Never invent content to fill a failed fetch.

### 2. Extract entities into structured rows

Read the whole document, then build a list of row objects. Each object uses
exactly these keys (full definitions and the controlled vocabularies live in
`references/schema.md` — read it if you're unsure about `entity_type` or
`concern_type` values):

```
entity_name, entity_type, aliases, location, role,
concern_type, concern_detail, confidence, quote, source_url
```

Core principles — internalize these rather than applying them mechanically:

**Scope: companies by default.** The target is *businesses* — corporations,
manufacturers, suppliers, subsidiaries, joint ventures, and brands that are
themselves a company. By default do **not** include government agencies,
regulators, courts, police, ministries, NGOs, charities, trade associations,
unions, ports, or universities, and **never** include bare countries,
nationalities, or individual people. Those non-company organizations belong in
the output only when the user clearly asks for them ("include agencies", "all
organizations", "everyone named"). The `entity_type` column still exists so that
opt-in output can be typed, but a default run is all `company`.

When the request is ambiguous — a loose "pull the entities/orgs out of this" —
lean to companies: extract them, then in your report name the non-company
organizations you set aside and offer to add them ("The piece also names Police
Scotland, the Home Office, and two courts — want those included?"). That beats
silently dropping them or padding the CSV with bodies the user may not want. And
when you genuinely can't tell whether something is in scope — is this "removed
from the list" section in or out? is this named thing a company or a product? —
ask the user rather than guess.

- **One row per distinct real-world organization.** An article will mention the
  same company many times, often spelled differently. Collapse those into a
  single row: the cleanest/most complete name goes in `entity_name`, the
  variants go in `aliases`, and you pick the single most informative sentence as
  the `quote`. Two genuinely different entities that happen to share a parent
  still get their own rows.

- **People are never their own row.** A person's name counts only when it *is*
  the business (a sole trader, an eponymous firm). When a person and their
  company are both named, the row is the company. If you're unsure whether a
  capitalized phrase is a company or a product/brand, keep it but mark
  `confidence` as `low` — more useful to the reviewer than dropping it silently
  or asserting it confidently.

- **Separate neutral role from concern.** `role` is how the entity functions in
  the supply chain or story — supplier, manufacturer, buyer, parent, subsidiary,
  regulator, investigator. `concern_type` + `concern_detail` capture whether the
  document alleges the entity did something wrong. A company can have a role and
  no concern (`concern_type` = `none`), or both. Keep allegations in the concern
  fields, not smuggled into `role`.

- **Ground everything in the text.** Locations, aliases, and especially concerns
  must be supported by the document. If the document gives no location, leave
  `location` blank — don't fill it from your own knowledge. (A place named in the
  entity's *own name* or stated in the text does count as grounded: "Shenzhen
  DJI" supports a `location` of Shenzhen, "Hangzhou Hikvision" supports Hangzhou.)
  A blank cell is honest; a guessed one is a bug. Your background knowledge is
  fine for *disambiguating* — knowing "BYD" is a company — just not for inventing
  facts the document doesn't state.

- **Quotes are verbatim.** Copy a short extract (aim for under ~240 characters)
  exactly as written, enough to show why the entity is in the document and to
  justify the concern if there is one. Don't paraphrase — the quote is the
  reviewer's evidence.

See `references/example.csv` for a couple of filled-in rows showing the
expected shape.

### 3. Serialize to CSV with the helper

Write your row list as JSON, then run the bundled serializer. This guarantees
correct escaping of the commas, quotation marks, and newlines that inevitably
appear inside `quote` and `concern_detail` — the single most common way
hand-written CSVs get corrupted.

```bash
python3 scripts/write_csv.py <rows.json> <output.csv>
```

- `<rows.json>`: a JSON array of your row objects (write it to a temp file).
- `<output.csv>`: the destination. Default to the current working directory,
  named `<slug>-entities.csv` where `<slug>` derives from the document title or,
  failing that, the URL's domain/filename. Honor any path the user specifies. If
  the file already exists, confirm before overwriting.

The script writes the header and rows in the fixed column order, fills any
missing key with an empty cell, and warns on unknown keys. If for some reason
`python3` isn't available, fall back to writing the CSV directly with `Write` —
but quote every field and escape embedded quotes (`"` → `""`), since that
fallback is exactly the failure mode the script exists to prevent.

### 4. Report back

Tell the user: how many companies you extracted, the output path, and anything
worth flagging:
- the non-company organizations you deliberately left out, with an offer to add
  them on request (per the scope rule above);
- rows you marked `low` confidence;
- whether the document genuinely named no companies — distinct from a fetch
  failure, where you couldn't read it at all.

## Edge cases

- **No companies found** → header-only CSV, and say you read the document and
  found none. Keep this distinct from a *fetch failure* (couldn't read the source
  at all — see step 1): never let an empty CSV stand in for "I couldn't open it."
  Don't force marginal mentions into rows just to have output.
- **Very long documents** → read and reason in chunks, but dedupe across chunks
  and emit one consolidated CSV. The same entity in chapter 1 and chapter 9 is
  one row.
- **Dense / list-like sources** (e.g. a sanctions list or a supplier table) →
  these can legitimately produce many rows; that's fine. Still apply the
  one-row-per-distinct-entity and grounding rules.
