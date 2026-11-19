#!/bin/sh
# b3: a malformed formula is a parse error, not a crash.
# Contract: parse raises src.parser.ParseError (an Exception subclass) and nothing else, quickly.
set -eu
cd "$(dirname "$0")/../../.."
export PYTHONDONTWRITEBYTECODE=1
python3 - <<'PY'
import random, signal, sys
from src.parser import parse, show, ParseError
assert issubclass(ParseError, Exception)
signal.signal(signal.SIGALRM, lambda *a: sys.exit("FAIL: parse hangs"))
signal.alarm(60)
malformed = ["=", "=1+", "=(1", "=1)", "=()", "=SUM(1,", "=SUM(1,2", "=1+*2", "=*1",
             "=\"abc", "=A1:", "=:A1", "=Sheet2!", "=!A1", "=1..2", "=1,2", "=@",
             "=SUM(1))", "=)(", "=A1 :", "=1^", "=&1", "=<1", "=1<", "=1>>2"]
bad = 0
for src in malformed:
    try:
        node = parse(src)
        bad += 1
        print("FAIL %r parsed as %s, want ParseError" % (src, show(node)))
    except ParseError:
        pass
    except Exception as e:
        bad += 1
        print("FAIL %r raised %s: %s, want ParseError" % (src, type(e).__name__, e))
# Random token soup: every input is either a node or a ParseError, never another exception.
rng = random.Random(1)
alphabet = ["A1", "$B$2", ":", "!", "Sheet2", "SUM", "(", ")", ",", "+", "-", "*", "/", "^", "&",
            "=", "<", ">", "%", "1", "2.5", "\"x\"", "TRUE", " ", "'", "\"", ".", "E", "#", ";"]
for i in range(5000):
    src = "=" + "".join(rng.choice(alphabet) for _ in range(rng.randint(0, 12)))
    try:
        show(parse(src))
    except ParseError:
        pass
    except Exception as e:
        bad += 1
        if bad < 20:
            print("FAIL %r raised %s: %s" % (src, type(e).__name__, e))
deep = "=" + "(" * 2000 + "1" + ")" * 2000
try:
    parse(deep)
except ParseError:
    pass
except Exception as e:
    bad += 1
    print("FAIL 2000 nested parentheses raised %s, want a node or ParseError" % type(e).__name__)
if bad:
    sys.exit(1)
print("ok b3")
PY
