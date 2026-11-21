#!/bin/sh
# b2 (plan a-v1-entry-display): the grid shows numbers as Calc's General format draws them in a column of the
# standard width. In headless Chrome/Chromium on the served page, Open a workbook of 75 numbers (A1:D20) and
# read each cell's text: 1234567890123456 shows 1.23457E+15, 1E-7 0.0000001, 1/3 0.333333333, 1E20 1E+020,
# 123456789012 1.23457E+11, 123456789.123 123456789.1; halves where the column cuts digits round away from zero
# (1234567890.5 -> 1234567891, 0.1234567895 -> 0.12345679, 1234565000000000 -> 1.23457E+15); plus held-out
# magnitudes (6.02214076E+23 -> 6.02214E+23, -9999999999.9 -> -1E+10, 9.9999E-07 stays E). Expected texts:
# a_v1_ed_calc.json "shown", from LibreOffice Calc 26.8.1.1 (a_v1_ed_probe.py: a PDF export of General cells in
# the standard column width, read back by pdftotext), never written by hand.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ed_b2.mjs
