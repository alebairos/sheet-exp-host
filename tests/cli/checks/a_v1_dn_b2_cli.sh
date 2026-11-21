#!/bin/sh
# b2 (plan a-v1-decimal-noise): ./engine prints numbers as LibreOffice reports them, not binary float noise.
# On the probe's workbook (tests/eval/checks/a_v1_dn_common.cases_book), every number ./engine prints for a
# formula, read back from its JSON, equals the number Calc shows for it (15 significant digits): =0.1+0.2
# prints 0.3, =1.1*3 and =3*1.1 print 3.3, the budget's =B2-B3-B4 (1200 - 850.5 - 384.02) prints -34.52,
# =100.1-100 prints 0.0999999999999943, =(1+1E-14)-1 prints 9.99200722162641e-15. Expected values:
# tests/eval/checks/a_v1_dn_calc.json, written by running LibreOffice Calc (a_v1_dn_probe.py).
set -eu
cd "$(dirname "$0")/../../eval/checks"
exec python3 - <<'PY'
from a_v1_dn_common import CALC, cases_book, engine, fail, finish
text, out = engine(cases_book())
cells, n = out["sheets"]["Cases"], 0
want = [(f"A{i + 1}", c) for i, c in enumerate(CALC["cases"]) if "number" in c]
for ref, c in want:
    got = cells.get(ref); n += 1
    if got != float(c["shown"]): fail(f"{c['formula']} prints {got!r}, Calc reports {c['shown']}")
b5, cb = out["sheets"]["Budget"].get("B5"), CALC["budget"]["B5"]
if b5 != float(cb["shown"]): fail(f"the budget's B5 =B2-B3-B4 prints {b5!r}, Calc reports {cb['shown']}")
finish(f"{n + 1} numbers print as LibreOffice reports them (0.3, 3.3, -34.52, ...)")
PY
