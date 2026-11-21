#!/bin/sh
# b2 (plan a-v1-parse-fidelity): malformed formulas, out-of-range numbers and empty-argument calls give
# LibreOffice's results. ./engine computes each of cases 15-85 of a_v1_pf_calc.json alone. They pin Calc's rule,
# read left to right: an unmatched ')' is Err:508; two operands side by side (=1 2, =1 (2), =(2)3) Err:509; a
# binary operator where an operand is expected (=*2, =1+*2, =&1) Err:510, while unary + and - are allowed
# (=1++2 is 3); the formula ending where an operand is expected gives Err:511 inside an open '(' (=(1+, =SUM(1,,
# =() ) and Err:520 at top level (=1+, =-, =A1:), except an empty open call (=SUM( is SUM() = 0); a missing final
# ')' is otherwise closed (=((1+2) is 3); a number literal out of range (=1E400, =1E-400) is Err:502. Empty calls:
# Err:511 except =SUM() =COUNT() =COUNTA() =PRODUCT() 0, =AVERAGE() #DIV/0!, =CONCATENATE() "". 40 of the cases
# were added in the replan as held-out forms. Expected values: from running LibreOffice Calc 26.8.1.1
# (a_v1_pf_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_pf_common import CALC, check; check(14, len(CALC["cases"]), "b2: malformed formulas and empty calls give Calc'"'"'s results")'
