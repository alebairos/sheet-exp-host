#!/bin/sh
# b2: CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM match Calc, coercion and errors included.
# Contract (plan i6-logic-text / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.logic_text.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. Text functions coerce numbers through to_text where Calc does; wrong types become
# #VALUE! where Calc does. TRIM collapses runs of spaces. BOOK cells are constants. Results compare
# type-strict: True never passes as 1.
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
        "A1": 5, "A2": "3", "A3": True, "A4": "abcd", "A5": "  a  b  ",
        "A6": "Hello", "A7": "", "B1": {"error": "#N/A"}, "B2": {"error": "#DIV/0!"},
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
    ("=CONCATENATE(\"a\",1)", "a1"),
    ("=CONCATENATE(\"x\",\"y\",\"z\")", "xyz"),
    ("=CONCATENATE(A4,A1)", "abcd5"),
    ("=CONCATENATE(A3,\"!\")", "TRUE!"),
    ("=CONCATENATE(B1,\"x\")", E("#N/A")),
    ("=CONCATENATE(\"x\",B2)", E("#DIV/0!")),
    ("=LEFT(\"abcd\",2)", "ab"),
    ("=LEFT(A4,3)", "abc"),
    ("=LEFT(\"abcd\")", "a"),
    ("=LEFT(1234,2)", "12"),
    ("=LEFT(A1,1)", "5"),
    ("=LEFT(\"abcd\",0)", ""),
    ("=LEFT(\"abcd\",-1)", E("#VALUE!")),
    ("=LEFT(B1,1)", E("#N/A")),
    ("=RIGHT(\"abcd\",2)", "cd"),
    ("=RIGHT(A4,3)", "bcd"),
    ("=RIGHT(\"abcd\")", "d"),
    ("=RIGHT(1234,2)", "34"),
    ("=RIGHT(\"abcd\",0)", ""),
    ("=RIGHT(\"abcd\",-1)", E("#VALUE!")),
    ("=RIGHT(B2,1)", E("#DIV/0!")),
    ("=MID(\"abcd\",2,2)", "bc"),
    ("=MID(A4,1,4)", "abcd"),
    ("=MID(\"abcd\",3,10)", "cd"),
    ("=MID(1234,2,2)", "23"),
    ("=MID(\"abcd\",0,1)", E("#VALUE!")),
    ("=MID(\"abcd\",1,-1)", E("#VALUE!")),
    ("=MID(B1,1,1)", E("#N/A")),
    ("=LEN(\"ab\")", 2),
    ("=LEN(A4)", 4),
    ("=LEN(123)", 3),
    ("=LEN(A1)", 1),
    ("=LEN(A7)", 0),
    ("=LEN(TRUE)", 4),
    ("=LEN(B1)", E("#N/A")),
    ("=UPPER(\"a\")", "A"),
    ("=UPPER(A6)", "HELLO"),
    ("=UPPER(\"AbC123\")", "ABC123"),
    ("=UPPER(B1)", E("#N/A")),
    ("=LOWER(\"A\")", "a"),
    ("=LOWER(A6)", "hello"),
    ("=LOWER(\"AbC123\")", "abc123"),
    ("=LOWER(B2)", E("#DIV/0!")),
    ("=TRIM(\"  a  b  \")", "a b"),
    ("=TRIM(A5)", "a b"),
    ("=TRIM(\"   \")", ""),
    ("=TRIM(\"x\")", "x"),
    ("=TRIM(B1)", E("#N/A")),
], "b2")
PY
