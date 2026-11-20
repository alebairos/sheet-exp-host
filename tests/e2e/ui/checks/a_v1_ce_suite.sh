#!/bin/sh
# b1, b2, b3 kept by the product (plan a-v1-cell-edit): the product carries its own browser test of in-cell editing,
# unittest tests in tests/e2e/ui/test_cell_edit.py that ./test.sh discovers (python3 -m unittest discover -s
# tests -t .); they start the browser named by $CHROME (first, before google-chrome or chromium on PATH), are
# not skipped and pass. They open a workbook on the served page, edit a formula in its cell with F2 and with a
# double-click, and open and close the editor on formula, error, number-like text and number cells unchanged.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import os, shutil, stat, sys, tempfile, unittest
real = os.environ.get("CHROME") or next(filter(None, map(shutil.which, ["google-chrome", "google-chrome-stable", "chromium", "chromium-browser"])), None)
if not real:
    print("FAIL no browser: set CHROME or put google-chrome or chromium on PATH"); sys.exit(1)
d = tempfile.mkdtemp(prefix="a-v1-ce-chrome-")
marker, wrapper = os.path.join(d, "started"), os.path.join(d, "chrome")
with open(wrapper, "w") as f:
    f.write('#!/bin/sh\ntouch "%s"\nexec "%s" "$@"\n' % (marker, shutil.which(real) or real))
os.chmod(wrapper, stat.S_IRWXU)
os.environ["CHROME"] = wrapper
picked = unittest.TestSuite()
def walk(s):
    for t in s:
        if isinstance(t, unittest.TestSuite): walk(t)
        elif t.id().startswith("tests.e2e.ui.test_cell_edit."): picked.addTest(t)
walk(unittest.defaultTestLoader.discover("tests", top_level_dir="."))
fails = []
if picked.countTestCases() == 0:
    fails.append("the product suite has no tests in tests/e2e/ui/test_cell_edit.py (discovered as ./test.sh does)")
else:
    r = unittest.TextTestRunner(stream=open(os.devnull, "w"), verbosity=0).run(picked)
    fails += ["%s fails: %s" % (t.id(), tb.strip().splitlines()[-1]) for t, tb in r.failures + r.errors]
    fails += ["%s was skipped: %s" % (t.id(), why) for t, why in r.skipped]
    if not os.path.exists(marker):
        fails.append("tests/e2e/ui/test_cell_edit.py never started the browser named by $CHROME")
for f in fails: print("FAIL " + f)
if not fails: print("ok the product's in-cell editing browser tests run and pass")
sys.exit(1 if fails else 0)
PY
