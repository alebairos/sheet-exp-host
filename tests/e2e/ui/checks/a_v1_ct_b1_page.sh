#!/bin/sh
# b1 through the page as shipped (plan a-v1-csv-text): in headless Chrome/Chromium on web/io/index.html as
# web/io/serve.py serves it, Open (#open) bank.csv (tests/web/io/checks/a_v1_ct_bank.csv): E2 shows 2134 and C2
# 4.5 as Calc's import shows them; Save CSV (#save-csv) right away downloads bank.csv byte for byte as the file;
# click G2, type =E2+1, Enter: G2 shows Calc's 2135; Save CSV again: every field of the file is saved exactly
# as written (02134, 4.50, ...) and G2 as 2135. Values: a_v1_ct_calc.json, from LibreOffice Calc (a_v1_ct_probe.py).
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ct_page.mjs
