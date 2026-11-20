#!/bin/sh
# b3: a cycle gives an error (does not hang).
# Contract: cells on a circular reference become {"error": "#REF!"} (SPEC-listed
# error used for a broken reference chain). recalculate returns promptly.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import json
import sys

from src.recalc import recalculate


def is_ref_error(v):
    return isinstance(v, dict) and v.get("error") == "#REF!"


bad = 0

# Two-node cycle.
book = {"sheets": {"Sheet1": {"A1": "=A2", "A2": "=A1"}}}
out = recalculate(book)
for addr in ("A1", "A2"):
    got = out["sheets"]["Sheet1"][addr]
    if not is_ref_error(got):
        bad += 1
        print("FAIL cycle %s: got %s want #REF!" % (addr, json.dumps(got)))

# Self-cycle.
book2 = {"sheets": {"Sheet1": {"A1": "=A1+1"}}}
out2 = recalculate(book2)
got = out2["sheets"]["Sheet1"]["A1"]
if not is_ref_error(got):
    bad += 1
    print("FAIL self-cycle: got %s want #REF!" % json.dumps(got))

# Cycle with a dependent outside: outside still computes; cycle cells error.
book3 = {"sheets": {"Sheet1": {
    "A1": "=A2",
    "A2": "=A1",
    "B1": 3,
    "B2": "=B1+1",
}}}
out3 = recalculate(book3)
if out3["sheets"]["Sheet1"]["B2"] != 4:
    bad += 1
    print("FAIL outside cycle: B2 got %s" % json.dumps(out3["sheets"]["Sheet1"]["B2"]))
for addr in ("A1", "A2"):
    if not is_ref_error(out3["sheets"]["Sheet1"][addr]):
        bad += 1
        print("FAIL cycle-with-out %s: %s" % (addr, json.dumps(out3["sheets"]["Sheet1"][addr])))

if bad:
    sys.exit(1)
print("ok b3")
PY
