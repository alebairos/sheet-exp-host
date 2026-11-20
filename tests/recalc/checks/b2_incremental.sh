#!/bin/sh
# b2: an edit recomputes only its dependents.
# Contract: recalculate(book, changed=[(sheet, addr), ...]) re-evaluates only the
# edited cells' transitive dependents (and the edited cell if it is a formula).
# Unrelated formulas are not passed to src.eval.evaluate again.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import json
import sys

import src.eval as eval_mod
from src.recalc import recalculate


def same(got, want):
    if isinstance(want, (bool, str, dict)) or want is None:
        return type(got) is type(want) and got == want
    return type(got) in (int, float) and not isinstance(got, bool) and abs(got - want) < 1e-9


source = {"sheets": {
    "Sheet1": {
        "A1": 2,
        "A2": "=A1+1",
        "A3": "=A2*10",
        "B1": 100,
        "B2": "=B1+1",
        "B3": "=B2+1",
    },
}}

calls = []
real_evaluate = eval_mod.evaluate


def spy(formula, book, sheet):
    calls.append((sheet, formula))
    return real_evaluate(formula, book, sheet)


eval_mod.evaluate = spy
try:
    out = recalculate(source, changed=[("Sheet1", "A1")])
finally:
    eval_mod.evaluate = real_evaluate

bad = 0
want_cells = {
    "A1": 2,
    "A2": 3,
    "A3": 30,
    "B1": 100,
    "B2": 101,
    "B3": 102,
}
for addr, want in want_cells.items():
    got = out["sheets"]["Sheet1"][addr]
    if not same(got, want):
        bad += 1
        print("FAIL value %s: got %s want %s" % (addr, json.dumps(got), json.dumps(want)))

formulas = [f for (_s, f) in calls]
for forbidden in ("=B1+1", "=B2+1"):
    if forbidden in formulas:
        bad += 1
        print("FAIL re-evaluated unrelated %s; calls=%s" % (forbidden, formulas))
for required in ("=A1+1", "=A2*10"):
    if required not in formulas:
        bad += 1
        print("FAIL missing dependent eval %s; calls=%s" % (required, formulas))

if bad:
    sys.exit(1)
print("ok b2")
PY
