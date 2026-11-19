#!/bin/sh
# b1: arithmetic, comparison, & and % match Calc (LibreOffice defaults).
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
               "B1": {"error": "#N/A"}, "B2": {"error": "#DIV/0!"}, "C1": "A"},
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
run([
    ("=1+2", 3), ("=10-4", 6), ("=6*7", 42), ("=10/4", 2.5), ("=2^10", 1024),
    ("=2^3^2", 64), ("=-2^2", 4), ("=-A1^2", 25), ("=1+2*3", 7), ("=(1+2)*3", 9),
    ("=50%", 0.5), ("=A5%", 0.5), ("=1+50%", 1.5), ("=50%=0.5", True),
    ("=A1+1", 6), ("=Sheet2!A1*2", 42), ("=A2+1", 4), ("=\"3\"*2", 6), ("=-\"2\"", -2),
    ("=TRUE+1", 2), ("=A3+A3", 2), ("=Z99+1", 1), ("=Z99", 0), ("=A1", 5), ("=A4", "abc"),
    ("=1=1", True), ("=3<>3", False), ("=2<3", True), ("=3<=2", False), ("=3>=3", True), ("=4>3", True),
    ("=\"a\"=\"A\"", True), ("=\"b\">\"a\"", True), ("=\"10\"<\"9\"", True), ("=10<\"9\"", True),
    ("=1<\"a\"", True), ("=TRUE=1", True), ("=TRUE=\"TRUE\"", False),
    ("=Z99=0", True), ("=Z99=\"\"", True), ("=A1=5", True),
    ("=\"a\"&1", "a1"), ("=1&2", "12"), ("=1&TRUE", "1TRUE"), ("=Z99&\"x\"", "x"),
    ("=0.1+0.2&\"\"", "0.3"), ("=1/4&\"\"", "0.25"), ("=A1&A4", "5abc"), ("=1+1&1", "21"),
], "b1")
PY
