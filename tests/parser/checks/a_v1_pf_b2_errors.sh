#!/bin/sh
# b2 (plan a-v1-parse-fidelity): malformed formulas, out-of-range numbers and empty-argument calls give
# LibreOffice's results. ./engine computes each of cases 15-45 of a_v1_pf_calc.json alone: =(1+ Err:511,
# =1+*2 Err:510, =1+ Err:520, =1 2 Err:509, =) and =(1+2)) Err:508, =1E400 and =1E-400 Err:502, =1++2 3, =SUM( 0;
# =MAX() =MIN() =MEDIAN() =AND() =IF() =LEN() =ROUND() ... Err:511, while =SUM() =COUNT() =COUNTA() =PRODUCT()
# are 0, =AVERAGE() #DIV/0! and =CONCATENATE() "". Expected values: a_v1_pf_calc.json, from running LibreOffice
# Calc 26.8.1.1 (a_v1_pf_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_pf_common import CALC, check; check(14, len(CALC["cases"]), "b2: malformed formulas and empty calls give Calc'"'"'s results")'
