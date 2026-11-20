#!/bin/sh
# b1: IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT, ISERROR match Calc.
# Contract (plan i6-logic-text / i3-evaluator): tests call src.eval.evaluate and src.values.to_json.
# Functions are discovered via src.functions.logic_text.FUNCTIONS (uppercase name → callable), merged by
# src.eval.registry(). Callables take positional args (Range for refs/ranges via .values(), else Value)
# and return a Value. IF uses Calc truthiness (0 and FALSE false; non-zero numbers and non-empty text
# true). IFERROR sees error Values. BOOK cells are constants. Results compare type-strict: True never
# passes as 1.
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
        "A1": 5, "A2": "3", "A3": True, "A4": "abc", "A5": 0, "A6": False,
        "A7": "", "B1": {"error": "#N/A"}, "B2": {"error": "#DIV/0!"},
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
    ("=IF(TRUE,1,2)", 1),
    ("=IF(FALSE,1,2)", 2),
    ("=IF(0,\"a\",\"b\")", "b"),
    ("=IF(1,\"a\",\"b\")", "a"),
    ("=IF(A5,\"a\",\"b\")", "b"),
    ("=IF(A3,10,20)", 10),
    ("=IF(A6,10,20)", 20),
    ("=IF(\"x\",1,2)", 1),
    ("=IF(\"\",1,2)", 2),
    ("=IF(A1>0,A1,0)", 5),
    ("=IF(FALSE,1)", False),
    ("=IF(B1,1,2)", E("#N/A")),
    ("=IFERROR(1/0,\"x\")", "x"),
    ("=IFERROR(5,\"x\")", 5),
    ("=IFERROR(B2,\"fallback\")", "fallback"),
    ("=IFERROR(A4,\"x\")", "abc"),
    ("=IFERROR(1+2,9)", 3),
    ("=AND(TRUE,1)", True),
    ("=AND(TRUE,TRUE)", True),
    ("=AND(TRUE,FALSE)", False),
    ("=AND(1,0)", False),
    ("=AND(A3,A1)", True),
    ("=AND(FALSE,B1)", E("#N/A")),
    ("=AND(TRUE,B1)", E("#N/A")),
    ("=OR(FALSE,0)", False),
    ("=OR(FALSE,1)", True),
    ("=OR(FALSE,FALSE)", False),
    ("=OR(A6,A5)", False),
    ("=OR(A6,A3)", True),
    ("=OR(FALSE,B1)", E("#N/A")),
    ("=NOT(FALSE)", True),
    ("=NOT(TRUE)", False),
    ("=NOT(0)", True),
    ("=NOT(1)", False),
    ("=NOT(A6)", True),
    ("=NOT(A3)", False),
    ("=NOT(B1)", E("#N/A")),
    ("=ISBLANK(Z9)", True),
    ("=ISBLANK(A1)", False),
    ("=ISBLANK(A7)", False),
    ("=ISBLANK(B1)", False),
    ("=ISNUMBER(1)", True),
    ("=ISNUMBER(A1)", True),
    ("=ISNUMBER(\"3\")", False),
    ("=ISNUMBER(A2)", False),
    ("=ISNUMBER(TRUE)", False),
    ("=ISNUMBER(A3)", False),
    ("=ISNUMBER(B1)", False),
    ("=ISTEXT(\"3\")", True),
    ("=ISTEXT(A2)", True),
    ("=ISTEXT(A4)", True),
    ("=ISTEXT(3)", False),
    ("=ISTEXT(A1)", False),
    ("=ISTEXT(TRUE)", False),
    ("=ISTEXT(A7)", True),
    ("=ISERROR(1/0)", True),
    ("=ISERROR(1)", False),
    ("=ISERROR(B1)", True),
    ("=ISERROR(B2)", True),
    ("=ISERROR(A4)", False),
    ("=ISERROR(\"x\")", False),
], "b1")
PY
