#!/bin/sh
# b1 (plan a-v1-entry-display): one entry rule for grid, formula bar and CSV, as Calc enters typed input. In
# headless Chrome/Chromium on web/io/index.html as web/io/serve.py serves it, with real keys: type 50%, 1e3,
# -2.5 and 'abc into grid cells A1:A4 (Enter) and into the formula bar for B1:B4 (Enter); Save JSON (#save-json)
# holds 0.5, 1000, -2.5 and "abc" in both columns. Open entry.csv (50%,1e3,-2.5,'abc): Save JSON holds the same
# in A1:D1. Values: a_v1_ed_calc.json "entry.typed", from LibreOffice Calc (a_v1_ed_probe.py). Calc's own CSV
# import keeps 'abc with its apostrophe ("entry.csv"); the bullet asks for abc everywhere, and so does this check.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ed_b1.mjs
