#!/bin/sh
# b1 (plan a-v1-sheet-tabs): one tab per sheet. On the served page (headless Chrome, real clicks) with order.json
# open (Prices, then Order): #sheet-tabs holds one [role=tab] per sheet, Prices then Order, Prices aria-selected;
# clicking Order shows Order in the grid (A1 Pens, B3 Calc's 34), selects that tab, and the formula bar names the
# sheet (#sheet-name: Order); clicking Prices shows Prices again (D1 Calc's 6, #sheet-name Prices).
# Values: a_v1_st_calc.json, from LibreOffice Calc 26.8.1.1 (a_v1_st_probe.py).
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_st.mjs b1
