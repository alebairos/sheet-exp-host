#!/bin/sh
# b1: SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN, STDEV match Calc on ranges with blanks and text.
# Contract (plan i5-math / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.math.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. In a range, blanks and text are skipped by SUM/AVERAGE/MIN/MAX/COUNT/PRODUCT/
# MEDIAN/STDEV; COUNTA counts every non-blank; STDEV is the sample (n-1) form. BOOK cells are constants.
# Results compare type-strict: True never passes as 1.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import json
import sys

from src.eval import evaluate
from src.values import to_json

# A5 blank; A3 text-looking number and A8 text skipped by numeric aggregates; A4 boolean as 1.
BOOK = {"sheets": {
    "Sheet1": {
        "A1": 1, "A2": 2, "A3": "3", "A4": True, "A6": 4.5, "A7": -2, "A8": "abc",
        "B1": 3, "B2": 1, "B3": 4, "B4": 1, "B5": 5, "B6": 9,
        "C1": 1, "C2": {"error": "#DIV/0!"}, "C3": 2,
        "D1": "x", "D3": "y",
        "H1": False, "H2": True, "H3": 0,
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
    ("=SUM(A1:A8)", 6.5),
    ("=SUM(B1:B6)", 23),
    ("=SUM(G1:G5)", 0),
    ("=SUM(D1:D3)", 0),
    ("=SUM(C1:C3)", E("#DIV/0!")),
    ("=SUM(A3)", 0),
    ("=AVERAGE(A1:A8)", 1.3),
    ("=AVERAGE(B1:B6)", 3.8333333333333335),
    ("=AVERAGE(G1:G5)", E("#DIV/0!")),
    ("=AVERAGE(D1:D3)", E("#DIV/0!")),
    ("=MIN(A1:A8)", -2),
    ("=MIN(B1:B6)", 1),
    ("=MIN(G1:G5)", 0),
    ("=MAX(A1:A8)", 4.5),
    ("=MAX(B1:B6)", 9),
    ("=COUNT(A1:A8)", 5),
    ("=COUNT(G1:G5)", 0),
    ("=COUNT(D1:D3)", 0),
    ("=COUNT(B1:B6)", 6),
    ("=COUNTA(A1:A8)", 7),
    ("=COUNTA(G1:G5)", 0),
    ("=COUNTA(D1:D3)", 2),
    ("=COUNTA(C1:C3)", 3),
    ("=PRODUCT(B1:B6)", 540),
    ("=PRODUCT(A1:A8)", -18),
    ("=PRODUCT(G1:G5)", 0),
    ("=MEDIAN(B1:B6)", 3.5),
    ("=MEDIAN(A1:A8)", 1),
    ("=MEDIAN(B1:B5)", 3),
    ("=MEDIAN(G1:G5)", E("#VALUE!")),
    ("=STDEV(B1:B6)", 2.9944392908634274),
    ("=STDEV(A1:A8)", 2.3345235059857505),
    ("=STDEV(1)", E("#DIV/0!")),
    ("=STDEV(G1:G5)", E("#DIV/0!")),
    ("=STDEV(2,4,4,4,5,5,7,9)", 2.138089935299395),
], "b1")
PY
