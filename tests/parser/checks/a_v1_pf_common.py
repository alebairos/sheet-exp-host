"""Shared by the a-v1-parse-fidelity checks: ./engine on the probe's formulas, compared with Calc's results."""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CALC = json.load(open(os.path.join(HERE, "a_v1_pf_calc.json")))


def engine_cell(formula):
    """./engine on the probe's data with `formula` in Sheet1!C1: its result, or a FAIL text when ./engine fails."""
    book = {"sheets": {k: dict(v) for k, v in CALC["data"].items()}}
    book["sheets"]["Sheet1"]["C1"] = formula
    p = subprocess.run([os.path.join(ROOT, "engine"), "-"], input=json.dumps(book), capture_output=True, text=True,
                       cwd=ROOT, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"), timeout=60)
    if p.returncode != 0:
        return "./engine exited %d: %s" % (p.returncode, (p.stderr.strip().splitlines() or [""])[-1][:120])
    return json.loads(p.stdout)["sheets"]["Sheet1"].get("C1")


def check(lo, hi, ok):
    """Cases lo..hi-1 of CALC, each alone in Sheet1!C1 next to the probe's data, against Calc's result."""
    fails = []
    for c in CALC["cases"][lo:hi]:
        got = engine_cell(c["formula"])
        if "number" in c: good = isinstance(got, (int, float)) and not isinstance(got, bool) and abs(got - c["number"]) <= 1e-9
        elif "text" in c: good = got == c["text"]
        else: good = got == {"error": c["error"]}
        if not good: fails.append("%s gives %s, Calc gives %s" % (c["formula"], json.dumps(got), json.dumps({k: v for k, v in c.items() if k != "formula"})))
    for f in fails: print("FAIL " + f)
    if not fails: print("ok " + ok)
    sys.exit(1 if fails else 0)
