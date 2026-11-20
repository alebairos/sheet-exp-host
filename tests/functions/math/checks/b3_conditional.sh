#!/bin/sh
# b3: SUMIF, COUNTIF, AVERAGEIF match Calc criteria (numeric, ">5", text).
# COUNTIF(E1:E9,"10")=2 and COUNTIF(A1:A8,"3")=1 verified on LibreOffice Calc 26.8 (text
# criterion matches both the numeric 10 / text "10", and text "3").
# Contract (plan i5-math / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.math.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. Criteria follow Calc: numeric equality, comparison prefixes, case-insensitive
# text (with * ? wildcards). BOOK cells are constants. Results compare type-strict: True never passes as 1.
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
        "A1": 1, "A2": 2, "A3": "3", "A4": True, "A6": 4.5, "A7": -2, "A8": "abc",
        "B1": 3, "B2": 1, "B3": 4, "B4": 1, "B5": 5, "B6": 9,
        "C1": 1, "C2": {"error": "#DIV/0!"}, "C3": 2,
        "E1": "apple", "E2": "banana", "E3": "Apple", "E4": "cherry",
        "E5": 10, "E6": 20, "E7": "b*n", "E9": "10",
        "F1": 1, "F2": 2, "F3": 3, "F4": 4, "F5": 5, "F6": 6, "F7": 7, "F8": 8, "F9": 9,
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
    ("=SUMIF(F1:F8,\">4\")", 26),
    ("=SUMIF(F1:F8,4)", 4),
    ("=SUMIF(F1:F8,\"4\")", 4),
    ("=SUMIF(F1:F8,\">5\")", 21),
    ("=SUMIF(E1:E8,\"apple\",F1:F8)", 4),
    ("=SUMIF(E1:E8,\"cherry\",F1:F8)", 4),
    ("=SUMIF(B1:B6,1)", 2),
    ("=SUMIF(A1:A8,\">1\")", 6.5),
    ("=COUNTIF(E1:E8,\"apple\")", 2),
    ("=COUNTIF(E1:E8,\"APPLE\")", 2),
    ("=COUNTIF(F1:F8,\">=3\")", 6),
    ("=COUNTIF(F1:F8,\">5\")", 3),
    ("=COUNTIF(E1:E9,10)", 1),
    ("=COUNTIF(E1:E9,\"10\")", 2),
    ("=COUNTIF(A1:A8,3)", 0),
    ("=COUNTIF(A1:A8,\"3\")", 1),
    ("=COUNTIF(E1:E8,\"b*\")", 2),
    ("=AVERAGEIF(F1:F8,\">4\")", 6.5),
    ("=AVERAGEIF(F1:F8,\">5\")", 7),
    ("=AVERAGEIF(E1:E8,\"apple\",F1:F8)", 2),
    ("=AVERAGEIF(F1:F8,\">100\")", E("#DIV/0!")),
    ("=AVERAGEIF(E1:E8,\"cherry\",F1:F8)", 4),
    ("=AVERAGEIF(A1:A8,\">0\")", 2.125),
], "b3")
PY
