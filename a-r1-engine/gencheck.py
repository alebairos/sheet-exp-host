"""gencheck.py BOOKS.json CALC.json OUTDIR: write the two a-r1-engine checks with Calc's answers embedded."""
import json, os, sys
books = json.load(open(sys.argv[1])); calc = json.load(open(sys.argv[2])); out = sys.argv[3]

COMMON = r'''
import json, os, re, subprocess, sys, unittest

ENGINE = os.path.abspath("engine")
FUNCS = """SUM AVERAGE MIN MAX COUNT COUNTA ROUND ROUNDUP ROUNDDOWN INT MOD ABS POWER SQRT PRODUCT SUMIF COUNTIF
AVERAGEIF MEDIAN STDEV IF IFERROR AND OR NOT ISBLANK ISNUMBER ISTEXT ISERROR CONCATENATE LEFT RIGHT MID LEN
UPPER LOWER TRIM VLOOKUP INDEX MATCH""".split()
fails = []

def same(g, w):
    if isinstance(w, bool) or isinstance(g, bool) or not isinstance(w, (int, float)) or not isinstance(g, (int, float)):
        return type(g) is type(w) and g == w
    return abs(g - w) <= 1e-9 * max(1.0, abs(w))

def run_cli(book, label):
    p = subprocess.run([sys.executable, ENGINE, "-"], input=json.dumps(book), capture_output=True, text=True, timeout=120)
    if p.returncode:
        fails.append("%s: the CLI exited %d: %s" % (label, p.returncode, p.stderr.strip()[-300:]))
        return None
    return json.loads(p.stdout)

def compare(book, want, label):
    got = run_cli(book, label)
    if got is None:
        return
    for sheet, cells in want["sheets"].items():
        for a, w in cells.items():
            g = got.get("sheets", {}).get(sheet, {}).get(a)
            if not same(g, w):
                fails.append("%s %s!%s %s: Calc %s, engine %s" % (label, sheet, a, book["sheets"][sheet][a], json.dumps(w), json.dumps(g)))

def formulas(book):
    return {(s, a): v for s, cells in book["sheets"].items() for a, v in cells.items() if isinstance(v, str) and v.startswith("=")}

REF = re.compile(r"(?:(\$?'?[A-Za-z_][A-Za-z0-9_ ]*'?)!)?\$?([A-Z]{1,3})\$?([0-9]+)(?::\$?([A-Z]{1,3})\$?([0-9]+))?")

def col(c):
    n = 0
    for ch in c: n = n * 26 + ord(ch) - 64
    return n

def longest_chain(book):
    """Longest path of formula-to-formula references (a range reaches every formula inside it)."""
    fs = formulas(book)
    deps = {}
    for (s, a), f in fs.items():
        body = re.sub(r'"[^"]*"', "", f)
        d = set()
        for m in REF.finditer(body):
            sh = (m.group(1) or s).strip("$'")
            c1, r1 = col(m.group(2)), int(m.group(3))
            c2, r2 = (col(m.group(4)), int(m.group(5))) if m.group(4) else (c1, r1)
            for (s2, a2) in fs:
                if s2 != sh: continue
                mm = re.match(r"([A-Z]+)([0-9]+)$", a2)
                cc, rr = col(mm.group(1)), int(mm.group(2))
                if min(c1, c2) <= cc <= max(c1, c2) and min(r1, r2) <= rr <= max(r1, r2):
                    d.add((s2, a2))
        deps[(s, a)] = d
    memo = {}
    sys.setrecursionlimit(100000)
    def depth(k, seen=()):
        if k in memo: return memo[k]
        if k in seen: return 0
        v = 1 + max([depth(x, seen + (k,)) for x in deps[k]] or [0])
        memo[k] = v
        return v
    return max([depth(k) for k in fs] or [0])

def product_books():
    """The product's own e2e workbooks: tests/e2e/engine/books/<name>.json with Calc's answers in <name>.calc.json."""
    d = os.path.join("tests", "e2e", "engine", "books")
    out = []
    if os.path.isdir(d):
        for f in sorted(os.listdir(d)):
            if f.endswith(".json") and not f.endswith(".calc.json"):
                ans = os.path.join(d, f[:-5] + ".calc.json")
                if not os.path.exists(ans):
                    fails.append("tests/e2e/engine/books/%s has no %s" % (f, f[:-5] + ".calc.json"))
                    continue
                out.append((f[:-5], json.load(open(os.path.join(d, f), encoding="utf-8")), json.load(open(ans, encoding="utf-8"))))
    return out

def product_suite():
    """The e2e tests are part of the product suite (./test.sh discovers them) and pass."""
    suite = unittest.defaultTestLoader.discover("tests", top_level_dir=".")
    picked = unittest.TestSuite()
    def walk(s):
        for t in s:
            if isinstance(t, unittest.TestSuite): walk(t)
            elif t.id().startswith("tests.e2e.engine.") or "tests.e2e.engine" in str(type(t)): picked.addTest(t)
    walk(suite)
    if picked.countTestCases() == 0:
        fails.append("the product suite has no tests under tests/e2e/engine (discovered from tests/, as ./test.sh does)")
        return
    r = unittest.TextTestRunner(stream=open(os.devnull, "w"), verbosity=0).run(picked)
    if not r.wasSuccessful():
        for t, tb in r.failures + r.errors:
            fails.append("e2e test %s fails: %s" % (t.id(), tb.strip().splitlines()[-1]))
'''

HEAD = '''#!/bin/sh
# %s
# Contract (plan a-r1-engine): the engine CLI (./engine, SPEC.md) computes whole workbooks as LibreOffice Calc does.
# 1. The workbook below goes through ./engine as one file; every cell must equal Calc's answer, which LibreOffice
#    headless computed over this exact workbook (numbers within 1e-9 relative; Calc's Err:5xx kept as Calc shows it).
# 2. The product carries its own end-to-end suite: tests/e2e/engine/books/<name>.json workbooks, each with Calc's
#    answers in <name>.calc.json, and unittest tests under tests/e2e/engine that ./test.sh discovers and that pass;
#    every product workbook computes through ./engine as its .calc.json says.
%s
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
export PYTHONIOENCODING=utf-8
python3 - <<'PY'
'''

def emit(name, desc, extra_doc, bname, tail):
    body = HEAD % (desc, extra_doc) + COMMON
    body += "\nBOOK = json.loads(r'''%s''')\n" % json.dumps(books[bname], ensure_ascii=False)
    body += "CALC = json.loads(r'''%s''')\n" % json.dumps(calc[bname], ensure_ascii=False)
    body += tail
    body += '''
if fails:
    print("FAIL (%d)" % len(fails))
    for f in fails[:60]:
        print("  " + f)
    sys.exit(1)
print("ok")
PY
'''
    p = os.path.join(out, name); open(p, "w").write(body); os.chmod(p, 0o755)

emit("a_r1_b1_workbooks.sh",
     "b1: multi-sheet workbooks mixing every function group compute as Calc does.",
     "# 3. Across the product's workbooks: at least one has two or more sheets with formulas reading another sheet, and\n"
     "#    the formulas name every one of SPEC's 40 functions.",
     "mixed", r'''
compare(BOOK, CALC, "check workbook")
pb = product_books()
if not pb:
    fails.append("no product workbooks in tests/e2e/engine/books")
named = set()
multi = False
for n, b, c in pb:
    compare(b, c, "tests/e2e/engine/books/%s.json" % n)
    fs = formulas(b)
    for f in fs.values():
        body = re.sub(r'"[^"]*"', "", f).upper()
        named |= {fn for fn in FUNCS if re.search(r"(?<![A-Z0-9_.])%s\s*\(" % fn, body)}
    if len(b["sheets"]) >= 2 and any("!" in re.sub(r'"[^"]*"', "", f) for f in fs.values()):
        multi = True
missing = [f for f in FUNCS if f not in named]
if pb and missing:
    fails.append("the product workbooks never call: " + ", ".join(missing))
if pb and not multi:
    fails.append("no product workbook has two sheets with a cross-sheet formula")
product_suite()
''')

emit("a_r1_b2_chain.sh",
     "b2: a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc.",
     "# 3. Among the product's workbooks, one holds a chain of at least 100 formulas, each reading the one before\n"
     "#    (the longest path of formula-to-formula references, a range reaching every formula inside it), and Calc's\n"
     "#    answers for it carry an error value.",
     "chain", r'''
n = longest_chain(BOOK)
if n < 100:
    fails.append("check workbook chain is %d long" % n)
compare(BOOK, CALC, "check workbook")
pb = product_books()
found = False
for name, b, c in pb:
    compare(b, c, "tests/e2e/engine/books/%s.json" % name)
    errs = any(isinstance(v, dict) and "error" in v for cells in c["sheets"].values() for v in cells.values())
    if errs and longest_chain(b) >= 100:
        found = True
if not found:
    fails.append("no product workbook in tests/e2e/engine/books has a chain of 100 formulas with an error in Calc's answers")
product_suite()
''')
