#!/bin/sh
# b1 (plan a-v1-csv-text), through web/io/io.js's createController({compute}) with compute = ./engine:
# openText("bank.csv", a_v1_ct_bank.csv) then saveCSV().text is the file byte for byte (02134, 00007, 4.50,
# -12.00, +3.10, 1000.00 and the quoted fields as written). The numbers compute: edit G2..G6 to =E2+1, =C2+C3,
# =SUM(C2:C6), =E3*2, =C5*10 and they show 2135, -7.5, 2195.6, 14, 31; then edit C3 to 5. After each step every
# field the user did not touch saves exactly as in the file, C3 saves as 5 and G2..G6 as Calc shows them.
# Values: a_v1_ct_calc.json, from LibreOffice Calc's default CSV import (a_v1_ct_probe.py), not by hand.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/web/io/checks/a_v1_ct_b1.mjs
