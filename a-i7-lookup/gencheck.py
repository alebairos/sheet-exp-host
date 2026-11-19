"""gencheck.py CASES.json GROUPS.json OUT.json META.json: write plan checks whose expected values are LO's."""
import json, sys
fix = json.load(open(sys.argv[1]))["sheets"]
groups = json.load(open(sys.argv[2]))["groups"]
out = json.load(open(sys.argv[3]))
meta = json.load(open(sys.argv[4]))
assert [f for _, f in groups] == [o[0] for o in out]
fixture = json.dumps({"sheets": fix}, ensure_ascii=False)
for g, m in meta["checks"].items():
    cases = [[f, r] for (gg, f), (_, r, _) in zip(groups, out) if gg == g]
    table = "[\n" + ",\n".join("  " + json.dumps(c, ensure_ascii=False) for c in cases) + "\n]"
    assert '"""' not in table and '"""' not in fixture
    src = f'''#!/bin/sh
# {g}: {m["text"]}.
{meta["contract"]}
# {m["rules"]}
set -eu
cd "$(dirname "$0")/{meta["up"]}"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONIOENCODING=utf-8
python3 - <<'PY'
import json
import sys

from src.eval import evaluate
from src.values import to_json

BOOK = json.loads(r"""{fixture}""")

CASES = json.loads(r"""{table}""")


def same(got, want):
    if isinstance(want, (bool, str, dict)) or want is None:
        return type(got) is type(want) and got == want
    return (type(got) in (int, float) and not isinstance(got, bool)
            and abs(got - want) <= 1e-9 * max(1.0, abs(want)))


bad = 0
for formula, want in CASES:
    try:
        got = to_json(evaluate(formula, BOOK, "Sheet1"))
    except Exception as e:  # noqa: BLE001 - a crash is a failure, reported
        got = "raised %s: %s" % (type(e).__name__, e)
    if not same(got, want):
        bad += 1
        print("FAIL %s: got %s, want %s (Calc)" % (formula, json.dumps(got, ensure_ascii=False),
                                                   json.dumps(want, ensure_ascii=False)))
if bad:
    print("%d of %d cases differ from Calc" % (bad, len(CASES)))
    sys.exit(1)
print("ok {g}: %d cases match Calc" % len(CASES))
PY
'''
    path = meta["dir"] + "/" + m["name"] + ".sh"
    open(path, "w", encoding="utf-8").write(src)
    # self-test: the embedded table round-trips to LO's answers
    t = src.split('CASES = json.loads(r"""', 1)[1].split('""")', 1)[0]
    assert json.loads(t) == cases
    print(path, len(cases))
