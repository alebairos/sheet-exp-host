#!/bin/sh
# b1, values kept (plan a-v1-entry-display, after gate review 2): the grid draws a number to fit its column, but what
# the user typed is kept. In headless Chrome on the shipped page (web/io/serve.py, /io/index.html), with real keys:
# type 123456789012, 3.141592653589793, '123 and 'TRUE into A1:A4. Save JSON holds Calc's values exactly (the two
# numbers to the last digit, the texts "123" and "TRUE"); F2 opens each with text that reads back the same ('123 and
# 'TRUE as Calc's input line shows them), and Enter changes nothing; Save CSV writes both numbers in full.
# Values: a_v1_ed_keep.json, from LibreOffice Calc (a_v1_ed_keep_probe.py). Steps: a_v1_ed_b1_keep.mjs.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ed_b1_keep.mjs
