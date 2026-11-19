#!/bin/sh
# b2: operator precedence and associativity match Calc.
# Calc (LibreOffice): unary minus binds tighter than ^, so -A1^2 is (-A1)^2;
# ^ is left-associative, so 2^3^2 is (2^3)^2 = 64; then % (postfix), ^, * /, + -, &, comparisons.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import sys
from src.parser import parse, show
cases = [
    ("=-A1^2", "(^ (neg A1) 2.0)"),
    ("=2^3^2", "(^ (^ 2.0 3.0) 2.0)"),
    ("=-2^-2", "(^ (neg 2.0) (neg 2.0))"),
    ("=1+2*3", "(+ 1.0 (* 2.0 3.0))"),
    ("=(1+2)*3", "(* (+ 1.0 2.0) 3.0)"),
    ("=1-2-3", "(- (- 1.0 2.0) 3.0)"),
    ("=8/2/2", "(/ (/ 8.0 2.0) 2.0)"),
    ("=2*3^2", "(* 2.0 (^ 3.0 2.0))"),
    ("=2*-3", "(* 2.0 (neg 3.0))"),
    ("=1--1", "(- 1.0 (neg 1.0))"),
    ("=--1", "(neg (neg 1.0))"),
    ("=+1", "1.0"),
    ("=50%", "(% 50.0)"),
    ("=50%*2", "(* (% 50.0) 2.0)"),
    ("=10%^2", "(^ (% 10.0) 2.0)"),
    ("=A1%%", "(% (% A1))"),
    ("=1+2&3", "(& (+ 1.0 2.0) 3.0)"),
    ("=\"a\"&\"b\"&\"c\"", "(& (& \"a\" \"b\") \"c\")"),
    ("=1&2=12", "(= (& 1.0 2.0) 12.0)"),
    ("=1+1=2", "(= (+ 1.0 1.0) 2.0)"),
    ("=A1<>B1", "(<> A1 B1)"),
    ("=A1<=B1", "(<= A1 B1)"),
    ("=A1>=B1", "(>= A1 B1)"),
    ("=A1<B1", "(< A1 B1)"),
    ("=A1>B1", "(> A1 B1)"),
    ("=1<2=TRUE", "(= (< 1.0 2.0) TRUE)"),
    ("=-SUM(A1:A2)^2", "(^ (neg (SUM A1:A2)) 2.0)"),
    ("=ABS(-2)*-(1+1)", "(* (ABS (neg 2.0)) (neg (+ 1.0 1.0)))"),
]
bad = 0
for src, want in cases:
    try:
        got = show(parse(src))
    except Exception as e:
        got = "raised %s: %s" % (type(e).__name__, e)
    if got != want:
        bad += 1
        print("FAIL %r: got %s, want %s" % (src, got, want))
if bad:
    sys.exit(1)
print("ok b2")
PY
