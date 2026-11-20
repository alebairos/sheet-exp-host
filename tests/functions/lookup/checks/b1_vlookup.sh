#!/bin/sh
# b1: VLOOKUP exact and sorted approximate match Calc.
# Contract (plan i7-lookup / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.lookup.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. BOOK cells are constants. Results compare type-strict: True never passes as 1.
#
# Calc pins (LibreOffice 26.8.1.1, measured): range_lookup omitted/TRUE/nonzero ⇒ approximate
# (largest first-column value ≤ lookup; first column sorted ascending); 0/FALSE ⇒ exact (#N/A if
# missing). Approximate below the first key is #N/A; above the last key returns the last row.
# Text lookup against numeric keys is #N/A (no type coercion; values._rank puts text after
# numbers). Column index <1, negative, or past the table width is Err:502 → #VALUE!
# (Calc does not emit #REF! for an oversized VLOOKUP column index).
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import json
import sys

from src.eval import evaluate
from src.values import to_json

# A1:C4 numeric keys ascending; E1:G3 text keys ascending. Constants only.
BOOK = {"sheets": {
    "Sheet1": {
        "A1": 1, "B1": "red", "C1": 10,
        "A2": 3, "B2": "green", "C2": 30,
        "A3": 5, "B3": "blue", "C3": 50,
        "A4": 7, "B4": "yellow", "C4": 70,
        "E1": "apple", "F1": "fruit", "G1": 1,
        "E2": "banana", "F2": "fruit", "G2": 2,
        "E3": "carrot", "F3": "veg", "G3": 3,
        "H1": {"error": "#N/A"},
        "H2": {"error": "#DIV/0!"},
    },
}}


def same(got, want):
    if isinstance(want, (bool, str, dict)) or want is None:
        return type(got) is type(want) and got == want
    return type(got) in (int, float) and not isinstance(got, bool) and abs(got - want) < 1e-9


def run(cases, label):
    bad = 0
    for formula, want in cases:
        try:
            got = to_json(evaluate(formula, BOOK, "Sheet1"))
        except Exception as e:  # noqa: BLE001 - a crash is a failure, reported
            got = "raised %s: %s" % (type(e).__name__, e)
        if not same(got, want):
            bad += 1
            print("FAIL %s: got %s, want %s" % (formula, json.dumps(got), json.dumps(want)))
    if bad:
        sys.exit(1)
    print("ok " + label)


E = lambda c: {"error": c}
run([
    # exact (range_lookup 0 / FALSE)
    ("=VLOOKUP(3,A1:C4,2,0)", "green"),
    ("=VLOOKUP(5,A1:C4,3,0)", 50),
    ("=VLOOKUP(7,A1:C4,2,FALSE)", "yellow"),
    ("=VLOOKUP(4,A1:C4,2,0)", E("#N/A")),
    ("=VLOOKUP(\"3\",A1:C4,2,0)", E("#N/A")),
    ("=VLOOKUP(\"banana\",E1:G3,2,0)", "fruit"),
    ("=VLOOKUP(\"zebra\",E1:G3,2,0)", E("#N/A")),
    ("=VLOOKUP(Z9,A1:C4,2,0)", E("#N/A")),
    # approximate (omitted / TRUE / nonzero); sorted ascending first column
    ("=VLOOKUP(5,A1:C4,2,1)", "blue"),
    ("=VLOOKUP(4,A1:C4,2,1)", "green"),
    ("=VLOOKUP(6,A1:C4,2)", "blue"),
    ("=VLOOKUP(6,A1:C4,2,TRUE)", "blue"),
    ("=VLOOKUP(4,A1:C4,2,2)", "green"),
    ("=VLOOKUP(0,A1:C4,2,1)", E("#N/A")),
    ("=VLOOKUP(100,A1:C4,2,1)", "yellow"),
    ("=VLOOKUP(\"blue\",E1:G3,2,1)", "fruit"),
    # column index errors (Calc Err:502 → #VALUE!)
    ("=VLOOKUP(3,A1:C4,0,0)", E("#VALUE!")),
    ("=VLOOKUP(3,A1:C4,-1,0)", E("#VALUE!")),
    ("=VLOOKUP(3,A1:C4,4,0)", E("#VALUE!")),
    # lookup-value errors propagate
    ("=VLOOKUP(H1,A1:C4,2,0)", E("#N/A")),
    ("=VLOOKUP(1/0,A1:C4,2,0)", E("#DIV/0!")),
    ("=VLOOKUP(H2,A1:C4,2,0)", E("#DIV/0!")),
], "b1")
PY
