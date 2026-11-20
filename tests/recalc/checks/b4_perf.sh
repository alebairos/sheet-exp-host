#!/bin/sh
# b4: 10,000 dependent cells recompute in under one second.
# Contract: a chain A1=1, A2=A1+1, ..., A10000=A9999+1 finishes recalculate in <1s
# and A10000 is 10000.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import sys
import time

from src.recalc import recalculate

n = 10000
cells = {"A1": 1}
for i in range(2, n + 1):
    cells["A%d" % i] = "=A%d+1" % (i - 1)
book = {"sheets": {"Sheet1": cells}}

t0 = time.perf_counter()
out = recalculate(book)
elapsed = time.perf_counter() - t0

got = out["sheets"]["Sheet1"]["A%d" % n]
if got != n:
    print("FAIL value A%d: got %r want %d" % (n, got, n))
    sys.exit(1)
if elapsed >= 1.0:
    print("FAIL slow: %.3fs for %d cells (want < 1s)" % (elapsed, n))
    sys.exit(1)
print("ok b4 (%.3fs)" % elapsed)
PY
