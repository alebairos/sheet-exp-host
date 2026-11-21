#!/bin/sh
# b2 (plan a-v1-sheet-tabs): editing the second sheet. On the served page with order.json open: on the Order
# tab type 5 into B1: Order!B3 recomputes to Calc's 65.5; on the Prices tab D1 (=SUM(Order!B1:B2)) recomputes to
# Calc's 9 and B1 is still 10.5; Save JSON writes Order.B1 = 5 and every other cell and formula as opened, on its
# own sheet. Values: a_v1_st_calc.json, from LibreOffice Calc 26.8.1.1 (a_v1_st_probe.py).
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_st.mjs b2
