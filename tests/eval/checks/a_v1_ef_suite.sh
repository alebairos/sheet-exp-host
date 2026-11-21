#!/bin/sh
# b1, b2 kept by the product (plan a-v1-engine-failure): the product carries its own tests of long formulas and
# engine failures, unittest tests in tests/eval/test_long_formulas.py that ./test.sh discovers (python3 -m
# unittest discover -s tests -t .): 1000- and 4096-term sums compute, past 8192 tokens a cell is Err:512 and the
# rest computes, and serve.py answers a failing compute with an HTTP error; they are not skipped and pass.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
exec python3 - <<'PY'
import os, sys, unittest
picked = unittest.TestSuite()
def walk(s):
    for t in s:
        if isinstance(t, unittest.TestSuite): walk(t)
        elif t.id().startswith("tests.eval.test_long_formulas."): picked.addTest(t)
walk(unittest.defaultTestLoader.discover("tests", top_level_dir="."))
fails = []
if picked.countTestCases() == 0:
    fails.append("the product suite has no tests in tests/eval/test_long_formulas.py (discovered as ./test.sh does)")
else:
    r = unittest.TextTestRunner(stream=open(os.devnull, "w"), verbosity=0).run(picked)
    fails += ["%s fails: %s" % (t.id(), tb.strip().splitlines()[-1]) for t, tb in r.failures + r.errors]
    fails += ["%s was skipped: %s" % (t.id(), why) for t, why in r.skipped]
for f in fails: print("FAIL " + f)
if not fails: print("ok the product's long-formula tests run and pass (%d)" % picked.countTestCases())
sys.exit(1 if fails else 0)
PY
