#!/bin/sh
# b2 (plan a-v1-cell-edit): same page and book.json as b1. For each of A3 (=A1+A2), C1 (=1/0), D1 (=0.1+0.2),
# D2 (the text 007), E1 (12.5) and E2 (hello), open the in-cell editor by F2 or by a real double-click and close
# it by Enter or by Escape without typing (24 round trips). After each one every cell of the book shows what
# Calc shows for it (#DIV/0!, 0.3, 007, TRUE for D3 =ISTEXT(D2), 3 for F1 =D1*10, ...) and Save JSON writes
# Sheet1 exactly as opened. Values: a_v1_ce_calc.json, from LibreOffice Calc (a_v1_ce_probe.py).
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ce_b2.mjs
