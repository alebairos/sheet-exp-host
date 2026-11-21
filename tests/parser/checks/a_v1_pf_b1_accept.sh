#!/bin/sh
# b1 (plan a-v1-parse-fidelity): formulas Calc accepts compute as Calc computes them. ./engine computes each of the first
# 14 cases of a_v1_pf_calc.json alone in Sheet1!C1 (data: Sheet1 A1 1, A2 2; 'My Sheet' A1 5, A2 6; S2 A1 3, A2 4):
# spaces around tokens (= SUM( A1 : A2 ) is 3, =1 + 2, = A1 * A2, =( 1 + 2 ) * 3), a sheet on a range's first end
# or on both (=SUM( 'My Sheet'!A1 : A2 ) 11, =SUM(S2!A1:S2!A2) 7), a missing final parenthesis (=SUM(1,2 is 3,
# =(1+2 is 3, =IF(A1=1,"one","other" is "one"), and an empty argument (=SUM(1,,2) is 3). Expected values:
# a_v1_pf_calc.json, from running LibreOffice Calc 26.8.1.1 (a_v1_pf_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_pf_common import check; check(0, 14, "b1: 14 formulas Calc accepts compute as in Calc")'
