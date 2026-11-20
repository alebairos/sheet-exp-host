#!/bin/sh
# b2: ROUND, ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER, SQRT match Calc, errors included.
# Contract (plan i5-math / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.math.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. ROUND is half away from zero (ROUND(1.5,0)=2, ROUND(-1.5,0)=-2). BOOK cells
# are constants. POWER(0,-1) is #DIV/0! to match src.eval's ^ / the certify reject
# (LibreOffice 26.8 shows #NUM! for the same case). Results compare type-strict: True never passes as 1.
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
        "C2": {"error": "#DIV/0!"},
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
    ("=ROUND(1.5,0)", 2),
    ("=ROUND(-1.5,0)", -2),
    ("=ROUND(2.5,0)", 3),
    ("=ROUND(-2.5,0)", -3),
    ("=ROUND(1.005,2)", 1.01),
    ("=ROUND(1234.567,-2)", 1200),
    ("=ROUND(A6,0)", 5),
    ("=ROUND(\"2.5\",0)", 3),
    ("=ROUND(\"abc\",1)", E("#VALUE!")),
    ("=ROUND(1/0,0)", E("#DIV/0!")),
    ("=ROUNDUP(1.21,1)", 1.3),
    ("=ROUNDUP(-1.21,1)", -1.3),
    ("=ROUNDUP(3.2)", 4),
    ("=ROUNDUP(1234,-2)", 1300),
    ("=ROUNDUP(\"x\",1)", E("#VALUE!")),
    ("=ROUNDDOWN(1.29,1)", 1.2),
    ("=ROUNDDOWN(-1.29,1)", -1.2),
    ("=ROUNDDOWN(1299,-2)", 1200),
    ("=ROUNDDOWN(2.5)", 2),
    ("=ROUNDDOWN(-2.5)", -2),
    ("=ROUNDDOWN(A8,0)", E("#VALUE!")),
    ("=INT(2.7)", 2),
    ("=INT(-2.7)", -3),
    ("=INT(\"3.9\")", 3),
    ("=INT(A8)", E("#VALUE!")),
    ("=INT(-0.5)", -1),
    ("=MOD(10,3)", 1),
    ("=MOD(-10,3)", 2),
    ("=MOD(10,-3)", -2),
    ("=MOD(-10,-3)", -1),
    ("=MOD(5,0)", E("#DIV/0!")),
    ("=MOD(5.5,2)", 1.5),
    ("=MOD(A8,2)", E("#VALUE!")),
    ("=ABS(-3.5)", 3.5),
    ("=ABS(\"-2\")", 2),
    ("=ABS(A8)", E("#VALUE!")),
    ("=ABS(C2)", E("#DIV/0!")),
    ("=POWER(2,10)", 1024),
    ("=POWER(2,-1)", 0.5),
    ("=POWER(0,0)", 1),
    ("=POWER(0,-1)", E("#DIV/0!")),
    ("=POWER(-1,0.5)", E("#NUM!")),
    ("=POWER(\"2\",3)", 8),
    ("=POWER(A8,2)", E("#VALUE!")),
    ("=POWER(10,400)", E("#NUM!")),
    ("=SQRT(16)", 4),
    ("=SQRT(2)", 1.4142135623730951),
    ("=SQRT(-1)", E("#NUM!")),
    ("=SQRT(0)", 0),
    ("=SQRT(\"9\")", 3),
    ("=SQRT(A8)", E("#VALUE!")),
    ("=SQRT(C2)", E("#DIV/0!")),
], "b2")
PY
