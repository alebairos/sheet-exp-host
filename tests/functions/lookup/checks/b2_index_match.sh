#!/bin/sh
# b2: INDEX and MATCH (types 0 and 1) match Calc, errors included.
# Contract (plan i7-lookup / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.lookup.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. BOOK cells are constants. Results compare type-strict: True never passes as 1.
#
# Calc pins (LibreOffice 26.8.1.1, measured): MATCH type 0 exact (#N/A if missing); type 1 or omitted
# is approximate on an ascending range (largest value ≤ lookup; below first key #N/A; above last key
# returns last position). INDEX(row, col) is 1-based; row/col 0 is #VALUE!; out of range is #REF!;
# negative index is Err:502 → #VALUE!. A single-column INDEX may take only the row argument.
# Text that coerces to a number matches that number under MATCH type 0.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import json
import sys

from src.eval import evaluate
from src.values import to_json

BOOK = {"sheets": {
    "Sheet1": {
        "A1": 1, "B1": "red", "C1": 10,
        "A2": 3, "B2": "green", "C2": 30,
        "A3": 5, "B3": "blue", "C3": 50,
        "A4": 7, "B4": "yellow", "C4": 70,
        "E1": "apple", "E2": "banana", "E3": "carrot",
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
    # INDEX
    ("=INDEX(A1:C4,2,2)", "green"),
    ("=INDEX(A1:C4,1,3)", 10),
    ("=INDEX(A1:C4,4,1)", 7),
    ("=INDEX(B1:B4,3)", "blue"),
    ("=INDEX(A1:C4,0,1)", E("#VALUE!")),
    ("=INDEX(A1:C4,1,0)", E("#VALUE!")),
    ("=INDEX(A1:C4,5,1)", E("#REF!")),
    ("=INDEX(A1:C4,1,4)", E("#REF!")),
    ("=INDEX(A1:C4,-1,1)", E("#VALUE!")),
    ("=INDEX(A1:C4,Z9,1)", E("#VALUE!")),
    ("=INDEX(A1:C4,H1,1)", E("#N/A")),
    ("=INDEX(A1:C4,1/0,1)", E("#DIV/0!")),
    # MATCH type 0 (exact)
    ("=MATCH(5,A1:A4,0)", 3),
    ("=MATCH(3,A1:A4,0)", 2),
    ("=MATCH(4,A1:A4,0)", E("#N/A")),
    ("=MATCH(\"5\",A1:A4,0)", 3),
    ("=MATCH(\"carrot\",E1:E3,0)", 3),
    ("=MATCH(Z9,A1:A4,0)", E("#N/A")),
    ("=MATCH(H1,A1:A4,0)", E("#N/A")),
    # MATCH type 1 / omitted (approximate, ascending)
    ("=MATCH(5,A1:A4,1)", 3),
    ("=MATCH(4,A1:A4,1)", 2),
    ("=MATCH(6,A1:A4)", 3),
    ("=MATCH(0,A1:A4,1)", E("#N/A")),
    ("=MATCH(100,A1:A4,1)", 4),
    ("=MATCH(\"blue\",E1:E3,1)", 2),
    # INDEX+MATCH composition
    ("=INDEX(B1:B4,MATCH(5,A1:A4,0))", "blue"),
    ("=INDEX(B1:B4,MATCH(4,A1:A4,1))", "green"),
], "b2")
PY
