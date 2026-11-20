#!/bin/sh
# b1: chains of formula cells compute in dependency order.
# Contract (plan i4-recalc): src.recalc.recalculate(book) -> computed workbook JSON
# (same shape as SPEC.md / ./engine). Formula strings become values; constants stay.
# Order is by reference deps, not sheet dictionary order.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import json
import sys

from src.recalc import recalculate
from src.values import to_json


def same(got, want):
    if isinstance(want, (bool, str, dict)) or want is None:
        return type(got) is type(want) and got == want
    return type(got) in (int, float) and not isinstance(got, bool) and abs(got - want) < 1e-9


def cell(book, sheet, addr):
    return book["sheets"][sheet][addr]


def expect(book, sheet, addr, want, label):
    got = cell(book, sheet, addr)
    if not same(got, want):
        print("FAIL %s: %s!%s got %s want %s" % (
            label, sheet, addr, json.dumps(got), json.dumps(want)))
        return 1
    return 0


bad = 0

# Insertion order is C, A, B; deps require B then A then C.
book = {"sheets": {
    "Sheet1": {
        "C1": "=A1+1",
        "A1": "=B1+1",
        "B1": 5,
    },
}}
out = recalculate(book)
bad += expect(out, "Sheet1", "B1", 5, "const")
bad += expect(out, "Sheet1", "A1", 6, "mid")
bad += expect(out, "Sheet1", "C1", 7, "end")

# Cross-sheet chain.
book2 = {"sheets": {
    "Sheet1": {"A1": 10, "A2": "=Sheet2!A1*2"},
    "Sheet2": {"A1": "=Sheet1!A1+1"},
}}
out2 = recalculate(book2)
bad += expect(out2, "Sheet1", "A1", 10, "x-const")
bad += expect(out2, "Sheet2", "A1", 11, "x-mid")
bad += expect(out2, "Sheet1", "A2", 22, "x-end")

# Longer chain still follows deps.
book3 = {"sheets": {"Sheet1": {
    "A1": 1,
    "A2": "=A1+1",
    "A3": "=A2+1",
    "A4": "=A3+1",
}}}
out3 = recalculate(book3)
for i, want in enumerate([1, 2, 3, 4], start=1):
    bad += expect(out3, "Sheet1", "A%d" % i, want, "chain")

if bad:
    sys.exit(1)
print("ok b1")
PY
