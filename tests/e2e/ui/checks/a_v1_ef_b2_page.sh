#!/bin/sh
# b2 through the page as shipped (plan a-v1-engine-failure): in headless Chrome/Chromium on web/io/index.html
# as web/io/serve.py serves it, Open book.json (A1 2, A2 =A1*3, C1 =SUM(A1:A2)); in the formula bar enter a
# 1000-term =1+1+...+1 into D1 (shows 1000) and a 4097-term one into D2 (shows Err:512); then type 7 into A1 in
# the grid: A2 shows 21 and C1 28, D1 still 1000, #message has no "Could not", the page throws nothing.
# Values: tests/eval/checks/a_v1_ef_calc.json, from LibreOffice Calc (a_v1_ef_probe.py).
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ef_page.mjs
