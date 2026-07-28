# Output schema & controlled vocabularies

The CSV has one row per distinct entity. Columns appear in exactly this order
(this matches `COLUMNS` in `scripts/write_csv.py`).

| # | column | required | contents |
|---|--------|----------|----------|
| 1 | `entity_name` | yes | The cleanest, most complete name of the organization. Prefer the full legal/common name over an abbreviation. |
| 2 | `entity_type` | yes | One of the entity types below. |
| 3 | `aliases` | no | Other names for the *same* entity: abbreviations, tickers, former names, native-language or romanized names, common misspellings used in the doc. `;`-separated. Blank if none. |
| 4 | `location` | no | Most specific location the document ties to the entity: city, region, country, or full address. A place in the entity's *own name* or stated in the text counts as grounded (e.g. "Shenzhen DJI" → Shenzhen). `;`-separated if several. Blank if the document gives none. |
| 5 | `role` | no | Neutral description of how the entity functions in the document. See role guidance below. |
| 6 | `concern_type` | yes | One or more concern tags below, `;`-separated. Use `none` when the document implies no wrongdoing by this entity. |
| 7 | `concern_detail` | no | Free-text specifics of the allegation/concern, grounded in the document. Blank when `concern_type` is `none`. |
| 8 | `confidence` | yes | `high` / `medium` / `low` — see rubric below. |
| 9 | `quote` | yes | Short verbatim extract (~≤240 chars) copied exactly from the source, showing why the entity is named (and justifying the concern, if any). |
| 10 | `source_url` | no | URL of the media. Blank for local files with no canonical URL. |

## entity_type vocabulary

By default the skill extracts **companies only**, so a default run is all
`company`. The other types apply only when the user has asked to include
non-company organizations (agencies, NGOs, etc.) — see the scope rule in
`SKILL.md`.

- `company` — commercial business: corporation, manufacturer, supplier, subsidiary, brand-as-business.
- `government_agency` — ministries, departments, customs/border agencies, militaries, regulators that are arms of a state.
- `ngo` — non-governmental / non-profit organizations, advocacy groups, watchdogs.
- `trade_association` — industry bodies, chambers of commerce, standards groups.
- `port` — seaports, airports, logistics terminals named as entities.
- `university` — universities and research institutes.
- `other` — a clear organization that fits none of the above. Use sparingly; prefer a specific type when defensible.

## concern_type vocabulary

Pick the tag(s) the document actually supports. Multiple are allowed.

- `forced_labor` — forced, bonded, or coerced labor; state-imposed labor transfer programs.
- `child_labor` — use of underage workers.
- `labor_violation` — other labor abuses: wage theft, unsafe conditions, union-busting (when not better captured by `safety`).
- `sanctions` — subject to sanctions, export controls, entity-list / blocklist designation, import bans.
- `environmental` — pollution, deforestation, illegal extraction, environmental harm.
- `corruption` — bribery, kickbacks, fraud against the public.
- `financial_misconduct` — accounting fraud, money laundering, securities violations.
- `human_rights` — broader human-rights abuses not captured above (surveillance, repression, complicity).
- `safety` — product or workplace safety failures, accidents, recalls.
- `legal_action` — named as a defendant / under investigation / charged, where the underlying wrong isn't otherwise specified.
- `other` — a documented concern fitting none of the above.
- `none` — the document does not allege wrongdoing by this entity.

`concern_type` records what the document *alleges or reports*, not a verdict. An
entity described as "accused of" or "under investigation for" something still
gets the tag; the `concern_detail` and `quote` carry the nuance (alleged vs.
proven).

## role guidance

`role` is the entity's neutral function in the narrative — keep allegations out
of it (those belong in the concern fields). Common values, not a closed list:
`supplier`, `manufacturer`, `buyer`, `importer`, `exporter`, `parent`,
`subsidiary`, `joint_venture`, `regulator`, `investigator`, `enforcer`,
`accuser`, `defendant`, `industry_body`, `customer`. Free text is fine when none
fit. Blank if the document gives no clear role.

## confidence rubric

- `high` — explicitly named organization, unambiguously a distinct real entity.
- `medium` — named but with some ambiguity: partial name, could be one of
  several entities, or unclear whether it's the parent or a subsidiary.
- `low` — inferred, or you're unsure it's an organization at all (might be a
  product, brand, or person). Worth surfacing for the reviewer rather than
  dropping.
