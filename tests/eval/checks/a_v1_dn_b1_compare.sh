#!/bin/sh
# b1 (plan a-v1-decimal-noise): comparisons and subtraction of nearly equal values as LibreOffice computes them.
# ./engine computes the probe's workbook (a_v1_dn_common.cases_book: 35 formulas in Cases!A1:A35 such as
# =0.1+0.2=0.3, =(0.1+0.2)-0.3, =1=1+1E-15, =1=1+1E-14, =(1+1E-14)-1, =B1-B2 over cells). Each result must be
# Calc's: a boolean exactly (=0.1+0.2=0.3 is TRUE), a number equal to Calc's to 15 significant digits and 0
# exactly where Calc gives 0 (=(0.1+0.2)-0.3 is 0), text exactly. Expected values: a_v1_dn_calc.json, written by
# running LibreOffice Calc 26.8.1.1 (a_v1_dn_probe.py), never by hand.
set -eu
cd "$(dirname "$0")"
exec python3 - <<'PY'
from a_v1_dn_common import CALC, cases_book, engine, fail, finish
_, out = engine(cases_book())
cells = out["sheets"]["Cases"]
for i, c in enumerate(CALC["cases"]):
    got, f = cells.get(f"A{i + 1}"), c["formula"]
    if "bool" in c:
        if got is not c["bool"]: fail(f"{f} gives {got!r}, Calc gives {c['shown']}")
    elif "number" in c:
        want = float(c["number"])
        if isinstance(got, bool) or not isinstance(got, (int, float)): fail(f"{f} gives {got!r}, Calc gives {c['shown']}")
        elif (want == 0 and got != 0) or f"{got:.15g}" != f"{want:.15g}": fail(f"{f} gives {got!r}, Calc gives {c['number']} (shown {c['shown']})")
    elif got != c["text"]: fail(f"{f} gives {got!r}, Calc gives {c['text']!r}")
finish(f"{len(CALC['cases'])} comparisons and subtractions match LibreOffice Calc")
PY
