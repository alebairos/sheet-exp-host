#!/bin/sh
# b1 (plan a-v1-error-help): in headless Chrome/Chromium on web/io/index.html as web/io/serve.py serves it, Open
# a workbook with one formula per error (=1/0, ="a"+1, =INDEX(A20:A21,5), =FOO(1), =MATCH(99,A20:A21,0),
# =1E308*10, =SQRT(-1), =MIN("x"), =IF(), and the cycle A10/A11). Clicking each error cell shows, beside the
# formula bar in #formula-bar .error-help, one visible line that names the error and contains Calc's own
# explanation (case-insensitive, without "Error: "): #DIV/0! "division by zero", #VALUE! "no value", #REF! "not a
# valid reference", #NAME? "invalid name", #N/A "value not available", #NUM! "invalid numeric value", Err:502
# "invalid argument", Err:504 "error in parameter list", Err:511 "variable missing", Err:522 "circular
# reference". A number cell shows none. Errors and texts: a_v1_eh_calc.json, from LibreOffice Calc 26.8.1.1
# (a_v1_eh_probe.py: computed headless; texts are its STR_LONG_ERR_* strings).
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_eh_page.mjs
