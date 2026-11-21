"""Shared by the a-v1-decimal-noise checks: Calc's answers (a_v1_dn_calc.json) and ./engine run as a user runs it."""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CALC = json.load(open(os.path.join(HERE, "a_v1_dn_calc.json")))
fails = []


def cases_book():
    """The probe's sheets as a SPEC workbook: Cases (A1.. the formulas, B1 =0.1+0.2, B2 0.3) and Budget."""
    cells = {"B1": "=0.1+0.2", "B2": 0.3}
    cells.update({f"A{i + 1}": c["formula"] for i, c in enumerate(CALC["cases"])})
    return {"sheets": {"Cases": cells, "Budget": CALC["budget"]["book"]}}


def engine(book):
    """./engine - on the workbook: (stdout text, parsed JSON)."""
    p = subprocess.run([os.path.join(ROOT, "engine"), "-"], input=json.dumps(book), capture_output=True, text=True,
                       cwd=ROOT, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"), timeout=60)
    if p.returncode != 0:
        print("FAIL ./engine exited %d: %s" % (p.returncode, p.stderr.strip()[-300:])); sys.exit(1)
    return p.stdout, json.loads(p.stdout)


def fail(m):
    fails.append(m)


def finish(ok):
    for f in fails:
        print("FAIL " + f)
    if not fails:
        print("ok " + ok)
    sys.exit(1 if fails else 0)
