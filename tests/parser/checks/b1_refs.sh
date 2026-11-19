#!/bin/sh
# b1: references, ranges and sheet references parse.
# Contract (plan i1-parser): src.parser.parse(formula) -> node; src.parser.show(node) -> canonical text.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import sys
from src.parser import parse, show
cases = [
    ("=A1", "A1"),
    ("=a1", "A1"),
    ("=$A$1", "$A$1"),
    ("=A$1", "A$1"),
    ("=$B7", "$B7"),
    ("=AB12", "AB12"),
    ("=A1:B6", "A1:B6"),
    ("=$A$1:B$6", "$A$1:B$6"),
    ("=Sheet2!A1", "Sheet2!A1"),
    ("=Sheet2!$B$3", "Sheet2!$B$3"),
    ("=Sheet2!A1:B2", "Sheet2!A1:B2"),
    ("='My Sheet'!C4", "'My Sheet'!C4"),
    ("=SUM(A1:A3,Sheet2!B1)", "(SUM A1:A3 Sheet2!B1)"),
    ("=sum(a1:a2)", "(SUM A1:A2)"),
    ("=A1+Sheet2!A1", "(+ A1 Sheet2!A1)"),
    ("=1", "1.0"),
    ("=2.5", "2.5"),
    ("=.5", "0.5"),
    ("=1E3", "1000.0"),
    ("=\"abc\"", "\"abc\""),
    ("=\"a\"\"b\"", "\"a\\\"b\""),
    ("=TRUE", "TRUE"),
    ("=false", "FALSE"),
    ("=PI()", "(PI)"),
    ("=IF(A1,,1)", "(IF A1 _ 1.0)"),
    ("=IF(A1>0,\"pos\",\"neg\")", "(IF (> A1 0.0) \"pos\" \"neg\")"),
    ("= A1 + 1 ", "(+ A1 1.0)"),
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
print("ok b1")
PY
