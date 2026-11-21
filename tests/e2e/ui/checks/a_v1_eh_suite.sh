#!/bin/sh
# b1, b2 kept by the product (plan a-v1-error-help): the product carries its own tests, unittest tests in
# tests/e2e/ui/test_error_help.py that ./test.sh discovers (python3 -m unittest discover -s tests -t .). They show
# each of the ten errors' explanations beside the formula bar in a browser, and they pin the engine CLI: for the
# formulas of a_v1_eh_calc.json "book", ./engine still prints exactly the error names Calc gives ("errors": #DIV/0!,
# #VALUE!, #REF!, #NAME?, #N/A, #NUM!, Err:502, Err:504, Err:511, Err:522). They are not skipped and pass.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
exec python3 - <<'PY'
import os, sys, unittest
picked = unittest.TestSuite()
def walk(s):
    for t in s:
        if isinstance(t, unittest.TestSuite): walk(t)
        elif t.id().startswith("tests.e2e.ui.test_error_help."): picked.addTest(t)
walk(unittest.defaultTestLoader.discover("tests", top_level_dir="."))
fails = []
if picked.countTestCases() == 0:
    fails.append("the product suite has no tests in tests/e2e/ui/test_error_help.py (discovered as ./test.sh does)")
else:
    r = unittest.TextTestRunner(stream=open(os.devnull, "w"), verbosity=0).run(picked)
    fails += ["%s fails: %s" % (t.id(), tb.strip().splitlines()[-1]) for t, tb in r.failures + r.errors]
    fails += ["%s was skipped: %s" % (t.id(), why) for t, why in r.skipped]
for f in fails: print("FAIL " + f)
if not fails: print("ok the product's error-help tests run and pass (%d)" % picked.countTestCases())
sys.exit(1 if fails else 0)
PY
