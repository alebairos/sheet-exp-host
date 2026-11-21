#!/bin/sh
# b3 (plan a-v1-keep-work): saving lets the user choose the file name. The page has a file name field
# (#save-name) holding the opened name (budget); after the user types my-budget into it, Save JSON downloads
# my-budget.json with the workbook and Save CSV downloads my-budget.csv with its values.
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_kw.mjs b3
