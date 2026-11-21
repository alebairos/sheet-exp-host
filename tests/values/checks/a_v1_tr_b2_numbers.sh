#!/bin/sh
# b2 (plan a-v1-text-rules): text-to-number coercion in arithmetic matches LibreOffice. ./engine computes, in one
# workbook, =A+0, =-A and =A*2 for each text of a_v1_tr_b2.json in cell A (layout: a_v1_tr_common.py): 126 texts
# (padded " 5 ", TRUE/true/False, $5 5$ -$5 ($5) (5) 5-, 1,000 and 1,234.5 but not 1,00 or 1 000, 50% 50 % -5%,
# 1e3 .5 5. +5, and what stays #VALUE!: €5, 1,5, --5, 5%%, tab or no-break space), 70 held out, and 113 formulas
# with literal text (=" 5 "+0, and the functions that read numbers the same way: =ROUND("(5)",0), =COUNT("$5"), ...).
# Expected values: from running LibreOffice Calc 26.8.1.1 (a_v1_tr_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_tr_common import check; check("a_v1_tr_b2.json", "b2: text reads as a number as in Calc")'
