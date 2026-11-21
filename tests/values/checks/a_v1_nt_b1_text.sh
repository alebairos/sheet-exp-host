#!/bin/sh
# b1 (plan a-v1-number-text): number-to-text conversion as LibreOffice does it. For each of the 54 number
# expressions in a_v1_nt_calc.json (the review's 1E-7, 1E15, 1E21, 123456789012345678 and 1E-20; the edges where
# Calc switches between decimal and E notation, around 1E-14, 1E15 and 2^53; halves at the 15th digit; and
# held-out values), ./engine computes ="x"&(n), =CONCATENATE(n), =LEFT(n,40) and =LEN(n); each text must be
# Calc's exactly (x0.0000001, 1000000000000000, 1E+021, 1.23456789012346E+017, 1E-020, ...) and each LEN
# Calc's number (21 for 123456789012345678, 6 for 1E-20). Expected values: a_v1_nt_calc.json, from running
# LibreOffice Calc 26.8.1.1 (a_v1_nt_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 - <<'PY'
import json, os, subprocess, sys
HERE = os.getcwd(); ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
cases = json.load(open("a_v1_nt_calc.json"))["cases"]
FORMS = {"amp": '="x"&({})', "concat": "=CONCATENATE({})", "left": "=LEFT({},40)", "len": "=LEN({})"}
cells = {f"{'ABCD'[j]}{i + 1}": f.format(c["n"]) for i, c in enumerate(cases) for j, f in enumerate(FORMS.values())}
p = subprocess.run([os.path.join(ROOT, "engine"), "-"], input=json.dumps({"sheets": {"S": cells}}), capture_output=True,
                   text=True, cwd=ROOT, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"), timeout=60)
if p.returncode != 0:
    print("FAIL ./engine exited %d: %s" % (p.returncode, p.stderr.strip()[-300:])); sys.exit(1)
out, fails = json.loads(p.stdout)["sheets"]["S"], []
for i, c in enumerate(cases):
    for j, k in enumerate(FORMS):
        got, want = out.get(f"{'ABCD'[j]}{i + 1}"), c[k]
        if got != want: fails.append("%s gives %s, Calc gives %s" % (FORMS[k].format(c["n"]), json.dumps(got), json.dumps(want)))
for f in fails: print("FAIL " + f)
if not fails: print("ok b1: %d number-to-text results match LibreOffice" % (len(cases) * len(FORMS)))
sys.exit(1 if fails else 0)
PY
