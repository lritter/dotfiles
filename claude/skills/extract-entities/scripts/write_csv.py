#!/usr/bin/env python3
"""Serialize extracted-entity rows (JSON) into a correctly-escaped CSV.

This is the deterministic half of the extract-entities skill. All entity
judgment happens upstream in the model; this script does nothing but write a
valid CSV. Keeping serialization here means commas, quotation marks, and
newlines inside free-text fields (quote, concern_detail) can never corrupt the
output — csv.writer handles the escaping.

Usage:
    python3 write_csv.py <rows.json> <output.csv>

<rows.json> is a JSON array of objects. Recognized keys are listed in COLUMNS
(the fixed output order). Missing keys become empty cells; unknown keys are
ignored with a warning so typos surface instead of silently dropping data.
An empty array yields a header-only file.
"""

import csv
import json
import sys

# Fixed column order. This is the contract with the skill and the schema doc;
# changing it means changing references/schema.md too.
COLUMNS = [
    "entity_name",
    "entity_type",
    "aliases",
    "location",
    "role",
    "concern_type",
    "concern_detail",
    "confidence",
    "quote",
    "source_url",
]


def _stringify(value):
    """Render a cell value as a string. Lists (e.g. aliases passed as an array
    rather than a pre-joined string) are joined with '; ' so the model can hand
    us either form. None becomes empty."""
    if value is None:
        return ""
    if isinstance(value, (list, tuple)):
        return "; ".join(str(v).strip() for v in value if str(v).strip())
    return str(value)


def write_csv(rows, out_path):
    if not isinstance(rows, list):
        raise ValueError(
            f"expected a JSON array of row objects, got {type(rows).__name__}"
        )

    known = set(COLUMNS)
    seen_unknown = set()

    with open(out_path, "w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(
            fh, fieldnames=COLUMNS, extrasaction="ignore", quoting=csv.QUOTE_MINIMAL
        )
        writer.writeheader()
        for i, row in enumerate(rows):
            if not isinstance(row, dict):
                raise ValueError(f"row {i} is not an object: {row!r}")
            for key in row:
                if key not in known and key not in seen_unknown:
                    seen_unknown.add(key)
                    print(
                        f"warning: ignoring unknown column '{key}'", file=sys.stderr
                    )
            writer.writerow({col: _stringify(row.get(col)) for col in COLUMNS})

    return len(rows)


def main(argv):
    if len(argv) != 3:
        print(__doc__, file=sys.stderr)
        return 2
    rows_path, out_path = argv[1], argv[2]
    with open(rows_path, encoding="utf-8") as fh:
        rows = json.load(fh)
    n = write_csv(rows, out_path)
    print(f"wrote {n} row(s) to {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
