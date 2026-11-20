#!/bin/sh
# b1 (plan a-v1-cell-edit): in headless Chrome/Chromium on web/io/index.html as web/io/serve.py serves it,
# Open (#open) book.json = a_v1_ce_calc.json's "book" (A1 10, A2 20, A3 =A1+A2, ...). With real mouse and keys
# (DevTools Input): click A3, F2: the in-cell editor (an input inside #grid's td) holds =A1+A2; End, type +1,
# Enter: A3 shows 31 and Save JSON (#save-json) writes A3 =A1+A2+1, every other cell as opened. A real
# double-click on A3 (clickCount 1 then 2): the editor holds =A1+A2+1; End, Backspace x2, type *2, Enter: A3
# shows 50, Save JSON writes A3 =A1+A2*2; the other cells show Calc's values; the page throws nothing.
# Shown values: a_v1_ce_calc.json, from LibreOffice Calc (a_v1_ce_probe.py), not written by hand.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ce_b1.mjs
