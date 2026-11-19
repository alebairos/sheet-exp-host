#!/bin/sh
# b2: errors propagate through operators as in Calc.
# Contract (plan i3-evaluator): src.eval.evaluate(formula, book, sheet) -> a src.values Value;
# src.values.to_json gives the CLI's JSON. Results compare type-strict: True never passes as 1.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
# --- shared fixture, inlined so this check stands alone ---
import json
import sys

from src.eval import evaluate
from src.values import to_json

BOOK = {"sheets": {
    "Sheet1": {"A1": 5, "A2": "3", "A3": True, "A4": "abc", "A5": 50, "A6": 0,
               "B1": {"error": "#N/A"}, "B2": {"error": "#DIV/0!"}, "B3": {"error": "#REF!"}, "C1": "A"},
    "Sheet2": {"A1": 21},
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
# --- cases ---
E = lambda c: {"error": c}
run([
    ("=1/0", E("#DIV/0!")), ("=0/0", E("#DIV/0!")), ("=A1/A6", E("#DIV/0!")), ("=A1/Z99", E("#DIV/0!")),
    ("=\"abc\"+1", E("#VALUE!")), ("=A4*2", E("#VALUE!")), ("=-A4", E("#VALUE!")), ("=A4%", E("#VALUE!")),
    ("=\"\"+1", E("#VALUE!")), ("=2^\"x\"", E("#VALUE!")),
    ("=1/0+1", E("#DIV/0!")), ("=1+1/0", E("#DIV/0!")), ("=-(1/0)", E("#DIV/0!")), ("=(1/0)%", E("#DIV/0!")),
    ("=1/0&\"x\"", E("#DIV/0!")), ("=\"x\"&1/0", E("#DIV/0!")), ("=(1/0)=1", E("#DIV/0!")), ("=1<(1/0)", E("#DIV/0!")),
    ("=B1+1", E("#N/A")), ("=B1*0", E("#N/A")), ("=-B1", E("#N/A")), ("=B1%", E("#N/A")),
    ("=B1&\"\"", E("#N/A")), ("=B1=B1", E("#N/A")), ("=B2+A1", E("#DIV/0!")), ("=(\"a\"+1)*2", E("#VALUE!")),
    ("=B2", E("#DIV/0!")), ("=2^(1/0)", E("#DIV/0!")),
    ("=NoSuchSheet!A1", E("#REF!")), ("=NoSuchSheet!A1+1", E("#REF!")), ("=-NoSuchSheet!A1", E("#REF!")),
    ("=B3+1", E("#REF!")), ("=B3*0", E("#REF!")), ("=B3&\"\"", E("#REF!")), ("=B3=1", E("#REF!")),
], "b2")
PY
