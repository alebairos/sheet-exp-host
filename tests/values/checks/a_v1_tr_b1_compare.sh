#!/bin/sh
# b1 (plan a-v1-text-rules): text comparison with = <> < > <= >= matches LibreOffice's default (case-sensitive,
# locale collation). ./engine computes, in one workbook, every case of a_v1_tr_b1.json (layout: a_v1_tr_common.py):
# Calc's order of 188 single characters (187 neighbouring pairs), 117 pairs of texts in cells with all six
# operators ("a" vs "A", é vs f, Zürich vs Zuse, co-op vs coop, ß vs ss, æ vs ae, tab, soft hyphen, ...),
# 65 pairs held out (probed only after the rules were written) and 8 literal formulas (="a"="A", ="é">"f", =""<"a", ...).
# Expected values: from running LibreOffice Calc 26.8.1.1 (a_v1_tr_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_tr_common import check; check("a_v1_tr_b1.json", "b1: text compares as in Calc")'
