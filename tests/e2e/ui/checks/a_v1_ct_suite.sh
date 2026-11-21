#!/bin/sh
# b1 kept by the product (plan a-v1-csv-text): the product carries its own test of the CSV round trip, unittest
# tests in tests/e2e/ui/test_csv_text.py that ./test.sh discovers (python3 -m unittest discover -s tests -t .);
# they open a CSV holding values such as 02134 and 4.50 through web/io/io.js's controller, save it untouched and
# after edits, and find every untouched field written as in the file; they are not skipped and pass.
# (tests/e2e/ui, not tests/web/io: tests/web has no __init__.py, so ./test.sh discovers nothing under it.)
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
exec python3 - <<'PY'
import os, sys, unittest
picked = unittest.TestSuite()
def walk(s):
    for t in s:
        if isinstance(t, unittest.TestSuite): walk(t)
        elif t.id().startswith("tests.e2e.ui.test_csv_text."): picked.addTest(t)
walk(unittest.defaultTestLoader.discover("tests", top_level_dir="."))
fails = []
if picked.countTestCases() == 0:
    fails.append("the product suite has no tests in tests/e2e/ui/test_csv_text.py (discovered as ./test.sh does)")
else:
    r = unittest.TextTestRunner(stream=open(os.devnull, "w"), verbosity=0).run(picked)
    fails += ["%s fails: %s" % (t.id(), tb.strip().splitlines()[-1]) for t, tb in r.failures + r.errors]
    fails += ["%s was skipped: %s" % (t.id(), why) for t, why in r.skipped]
for f in fails: print("FAIL " + f)
if not fails: print("ok the product's CSV round-trip tests run and pass (%d)" % picked.countTestCases())
sys.exit(1 if fails else 0)
PY
