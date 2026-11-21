#!/bin/sh
# b1 (plan a-v1-engine-failure): ./engine computes a workbook with very long formulas (a_v1_ef_common.LONG:
# 1000-, 4095-, 4096-, 4097- and 5000-term sums of 1, a 1000-term sum of A1, a 2000-term chain of A1-A1-...,
# and =B1+B2) next to ordinary cells (A1 2, A2 =A1*3, C1 =SUM(A1:A2)). It exits 0 within 60 s with no
# traceback, and every cell is Calc's: 1000, 4095, 4096, 2000 and -3996 where Calc computes, {"error":
# "Err:512"} (Calc's formula overflow, past 8192 tokens) for the 4097- and 5000-term sums and for =B1+B2,
# and 2, 6, 8 for the ordinary cells. Expected values: a_v1_ef_calc.json, from running LibreOffice Calc
# 26.8.1.1 (a_v1_ef_probe.py), not written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 - <<'PY'
import json, os, subprocess, sys
from a_v1_ef_common import CALC, LONG, OTHER, ROOT, calc_json
book = {"sheets": {"Sheet1": {**OTHER, **LONG}}}
try:
    p = subprocess.run([os.path.join(ROOT, "engine"), "-"], input=json.dumps(book), capture_output=True, text=True,
                       cwd=ROOT, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"), timeout=60)
except subprocess.TimeoutExpired:
    print("FAIL ./engine took more than 60 s"); sys.exit(1)
if p.returncode != 0 or "Traceback" in p.stderr:
    print("FAIL ./engine exited %d: %s" % (p.returncode, p.stderr.strip().splitlines()[-1:] or "")); sys.exit(1)
cells, fails = json.loads(p.stdout)["sheets"]["Sheet1"], []
for ref in CALC["results"]:
    want, got = calc_json(ref), cells.get(ref)
    ok = got == want if isinstance(want, dict) else (isinstance(got, (int, float)) and not isinstance(got, bool) and abs(got - want) <= 1e-9 * max(1, abs(want)))
    if not ok: fails.append("%s (%s) gives %s, Calc gives %s" % (ref, (OTHER.get(ref) or LONG[ref])[:24] + "...", json.dumps(got), json.dumps(want)))
for f in fails: print("FAIL " + f)
if not fails: print("ok b1: long formulas give Calc's values or Err:512, every other cell computes")
sys.exit(1 if fails else 0)
PY
