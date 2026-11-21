#!/bin/sh
# b1, b2, b3 kept by the product (plan a-v1-grid-keys): the product carries its own browser tests, unittest tests
# in tests/e2e/ui/test_grid_keys.py that ./test.sh discovers (python3 -m unittest discover -s tests -t .), of Tab
# and Shift+Tab, of a click while editing, and of leaving the formula bar by a click; not skipped, and passing.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
exec python3 - <<'PY'
import os, sys, unittest
picked = unittest.TestSuite()
def walk(s):
    for t in s:
        if isinstance(t, unittest.TestSuite): walk(t)
        elif t.id().startswith("tests.e2e.ui.test_grid_keys."): picked.addTest(t)
walk(unittest.defaultTestLoader.discover("tests", top_level_dir="."))
fails = []
if picked.countTestCases() == 0:
    fails.append("the product suite has no tests in tests/e2e/ui/test_grid_keys.py (discovered as ./test.sh does)")
else:
    r = unittest.TextTestRunner(stream=open(os.devnull, "w"), verbosity=0).run(picked)
    fails += ["%s fails: %s" % (t.id(), tb.strip().splitlines()[-1]) for t, tb in r.failures + r.errors]
    fails += ["%s was skipped: %s" % (t.id(), why) for t, why in r.skipped]
for f in fails: print("FAIL " + f)
if not fails: print("ok the product's grid-keys tests run and pass (%d)" % picked.countTestCases())
sys.exit(1 if fails else 0)
PY
