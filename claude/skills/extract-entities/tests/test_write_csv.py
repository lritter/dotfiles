#!/usr/bin/env python3
"""Tests for the extract-entities CSV serializer.

Run: python3 tests/test_write_csv.py  (from the skill root)

These exercise the failure mode the script exists to prevent — special
characters inside free-text cells — plus the key-handling contract.
"""

import csv
import io
import json
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL_ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(SKILL_ROOT, "scripts"))

import write_csv  # noqa: E402

COLUMNS = write_csv.COLUMNS


def _run(rows):
    """Serialize rows to a temp CSV, return parsed rows (list of dicts) and the
    raw header list."""
    out = tempfile.NamedTemporaryFile(
        mode="w", suffix=".csv", delete=False, encoding="utf-8"
    )
    out.close()
    write_csv.write_csv(rows, out.name)
    with open(out.name, newline="", encoding="utf-8") as fh:
        reader = csv.reader(fh)
        header = next(reader)
        body = list(reader)
    os.unlink(out.name)
    # Re-read as dicts for convenient field access.
    parsed = [dict(zip(header, r)) for r in body]
    return header, parsed


passed = 0
failed = 0


def check(name, condition):
    global passed, failed
    if condition:
        passed += 1
        print(f"  ok   {name}")
    else:
        failed += 1
        print(f"  FAIL {name}")


# 1. Header + column order
header, _ = _run([])
check("empty array yields header-only file", header == COLUMNS)

# 2. Special characters survive a round-trip without corrupting structure
nasty = {
    "entity_name": "Acme, Inc.",
    "entity_type": "company",
    "quote": 'He said "they used forced labor," then hung up.',
    "concern_detail": "Line one.\nLine two, with comma.",
    "source_url": "https://example.com/a,b",
}
header, parsed = _run([nasty])
check("special chars: exactly one data row parsed", len(parsed) == 1)
check("special chars: comma in name preserved", parsed[0]["entity_name"] == "Acme, Inc.")
check(
    "special chars: embedded quotes preserved",
    parsed[0]["quote"] == 'He said "they used forced labor," then hung up.',
)
check(
    "special chars: newline inside cell preserved",
    parsed[0]["concern_detail"] == "Line one.\nLine two, with comma.",
)
check(
    "special chars: comma in url preserved",
    parsed[0]["source_url"] == "https://example.com/a,b",
)

# 3. Missing keys become empty cells
header, parsed = _run([{"entity_name": "Solo Corp", "entity_type": "company"}])
check("missing keys: all columns present", list(parsed[0].keys()) == COLUMNS)
check("missing keys: absent field is empty string", parsed[0]["location"] == "")
check("missing keys: provided field intact", parsed[0]["entity_name"] == "Solo Corp")

# 4. Unknown keys ignored + warned (run as subprocess to capture stderr)
with tempfile.NamedTemporaryFile(
    mode="w", suffix=".json", delete=False, encoding="utf-8"
) as jf:
    json.dump([{"entity_name": "X", "bogus_col": "drop me"}], jf)
    rows_path = jf.name
out_path = rows_path + ".csv"
proc = subprocess.run(
    [sys.executable, os.path.join(SKILL_ROOT, "scripts", "write_csv.py"), rows_path, out_path],
    capture_output=True,
    text=True,
)
with open(out_path, newline="", encoding="utf-8") as fh:
    r2 = list(csv.reader(fh))
os.unlink(rows_path)
os.unlink(out_path)
check("unknown keys: header still canonical", r2[0] == COLUMNS)
check("unknown keys: warning emitted to stderr", "bogus_col" in proc.stderr)
check("unknown keys: value not present in output", "drop me" not in "".join(r2[1]))

# 5. List-valued cells (aliases as array) joined with '; '
header, parsed = _run([{"entity_name": "Y", "aliases": ["ABC", "A.B.C.", "Alpha"]}])
check("list cell: joined with '; '", parsed[0]["aliases"] == "ABC; A.B.C.; Alpha")

# 6. None values become empty
header, parsed = _run([{"entity_name": "Z", "location": None, "aliases": None}])
check("none value: rendered as empty string", parsed[0]["location"] == "")

# 7. Non-list input rejected
try:
    write_csv.write_csv({"not": "a list"}, "/tmp/should_not_exist.csv")
    check("non-list input raises", False)
except ValueError:
    check("non-list input raises", True)

print(f"\n{passed} passed, {failed} failed")
sys.exit(1 if failed else 0)
