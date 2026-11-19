#!/bin/sh
# b3: an unknown function is #NAME?.
# Contract (plan i3-evaluator): src.eval.evaluate(formula, book, sheet) -> a src.values Value;
# src.values.to_json gives the CLI's JSON. Results compare type-strict: True never passes as 1.
# Clarification 2026-11-19: register/registry live in src.eval (not src.functions).
# Also pins how the evaluator calls a function registered with src.eval.register (the function
# intents build on it): positional args; a reference or range argument arrives as a src.eval.Range whose
# values() lists every cell row by row (blanks included); any other argument as a src.values Value,
# errors included (the function decides); the function returns a Value.
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
from src.eval import register
from src.eval import Range
from src.values import from_json, to_json
seen = {}
@register("ZZPROBE")
def _probe(*args):
    seen["args"] = args
    return from_json(len(args))
@register("ZZFIRST")
def _first(*args):
    a = args[0]
    return a.values()[0] if isinstance(a, Range) else a
E = lambda c: {"error": c}
run([
    ("=NOSUCHFUNCTION(1)", E("#NAME?")), ("=nosuch()", E("#NAME?")), ("=FOO(1/0)", E("#NAME?")),
    ("=FOO(1)+1", E("#NAME?")), ("=1+FOO()", E("#NAME?")), ("=foo", E("#NAME?")), ("=foo+1", E("#NAME?")),
    ("=zzprobe(1,2,3)", 3), ("=ZZFIRST(\"x\")", "x"), ("=ZZFIRST(1/0)", E("#DIV/0!")), ("=ZZFIRST(A1:A2)+1", 6),
    ("=ZZPROBE(ZZPROBE(),1)+1", 3),
], "b3")
from src.eval import evaluate
bad = 0
evaluate("=ZZPROBE(1, A1:B3, Sheet2!A1, Z9, \"t\", 1/0)", BOOK, "Sheet1")
args = seen.get("args", ())
if len(args) != 6:
    sys.exit("FAIL ZZPROBE got %d args, want 6" % len(args))
rng, one, blank = args[1], args[2], args[3]
if not isinstance(rng, Range) or [to_json(v) for v in rng.values()] != [5, {"error": "#N/A"}, "3", {"error": "#DIV/0!"}, True, None]:
    bad += 1; print("FAIL A1:B3 should arrive as a Range of 6 values row by row, got %r" % (rng,))
if not isinstance(one, Range) or [to_json(v) for v in one.values()] != [21]:
    bad += 1; print("FAIL Sheet2!A1 should arrive as a one-cell Range, got %r" % (one,))
if not isinstance(blank, Range) or [to_json(v) for v in blank.values()] != [None]:
    bad += 1; print("FAIL a blank Z9 should arrive as a one-cell Range holding a blank, got %r" % (blank,))
if [to_json(args[0]), to_json(args[4]), to_json(args[5])] != [1, "t", {"error": "#DIV/0!"}]:
    bad += 1; print("FAIL scalar args should arrive as Values, errors included, got %r" % (args,))
if bad:
    sys.exit(1)
print("ok b3 calling convention")
PY
