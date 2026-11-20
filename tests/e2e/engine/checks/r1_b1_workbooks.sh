#!/bin/sh
# b1: multi-sheet workbooks mixing every function group compute as Calc does.
# Contract (plan r1-engine): the engine CLI (./engine, SPEC.md) computes whole workbooks as LibreOffice Calc does.
# 1. The workbook below goes through ./engine as one file; every cell must equal Calc's answer, which LibreOffice
#    headless computed over this exact workbook (numbers within 1e-9 relative; Calc's Err:5xx kept as Calc shows it).
# 2. The product carries its own end-to-end suite: tests/e2e/engine/books/<name>.json workbooks, each with Calc's
#    answers in <name>.calc.json, and unittest tests under tests/e2e/engine that ./test.sh discovers and that pass;
#    every product workbook computes through ./engine as its .calc.json says.
# 3. Across the product's workbooks: at least one has two or more sheets with formulas reading another sheet, and
#    the formulas name every one of SPEC's 40 functions.
set -eu
cd "$(dirname "$0")/../../../.."
export PYTHONDONTWRITEBYTECODE=1
export PYTHONIOENCODING=utf-8
python3 - <<'PY'

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
    p = subprocess.run([ENGINE, "-"], input=json.dumps(book), capture_output=True, text=True, timeout=120)
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
    try:
        suite = unittest.defaultTestLoader.discover("tests", top_level_dir=".")
    except ImportError as e:
        fails.append("the product suite is not importable under tests/ (as ./test.sh discovers): %s" % e)
        return
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

BOOK = json.loads(r'''{"sheets": {"Data": {"A1": "Item", "B1": "Category", "C1": "Qty", "D1": "Price", "E1": "Total", "A2": "apple", "B2": "fruit", "C2": 12, "D2": 0.5, "E2": "=C2*D2", "A3": "Banana", "B3": "fruit", "C3": 7, "D3": 0.25, "E3": "=C3*D3", "A4": "carrot", "B4": "veg", "C4": 20, "D4": 0.1, "E4": "=C4*D4", "A5": "dill", "B5": "herb", "C5": 3, "D5": 1.75, "E5": "=C5*D5", "A6": "eggplant", "B6": "veg", "C6": 4, "D6": 1.2, "E6": "=C6*D6", "A7": "fig", "B7": "fruit", "C7": 9, "D7": 0.8, "E7": "=C7*D7", "A8": "garlic", "B8": "herb", "C8": 15, "D8": 0.3, "E8": "=C8*D8", "A9": "  kale  ", "B9": "veg", "C9": "6", "D9": 2, "E9": "=C9*D9", "G1": "Category", "H1": "Discount", "G2": "fruit", "H2": 0.1, "G3": "herb", "H3": 0.05, "G4": "veg", "H4": 0, "F1": "Net", "F2": "=ROUND(E2*(1-VLOOKUP(B2,$G$2:$H$4,2,0)),2)", "F3": "=ROUND(E3*(1-VLOOKUP(B3,$G$2:$H$4,2,0)),2)", "F4": "=ROUND(E4*(1-VLOOKUP(B4,$G$2:$H$4,2,0)),2)", "F5": "=ROUND(E5*(1-VLOOKUP(B5,$G$2:$H$4,2,0)),2)", "F6": "=ROUND(E6*(1-VLOOKUP(B6,$G$2:$H$4,2,0)),2)", "F7": "=ROUND(E7*(1-VLOOKUP(B7,$G$2:$H$4,2,0)),2)", "F8": "=ROUND(E8*(1-VLOOKUP(B8,$G$2:$H$4,2,0)),2)", "F9": "=ROUND(E9*(1-VLOOKUP(B9,$G$2:$H$4,2,0)),2)", "A11": true, "B11": "=IF(A11,\"on\",\"off\")"}, "Summary": {"A1": "=SUM(Data!E2:E9)", "A2": "=SUM(Data!F2:F9)", "A3": "=AVERAGE(Data!C2:C9)", "A4": "=COUNT(Data!C2:C9)", "A5": "=COUNTA(Data!A1:A12)", "A6": "=MIN(Data!D2:D9)", "A7": "=MAX(Data!E2:E9)", "A8": "=MEDIAN(Data!C2:C9)", "A9": "=ROUND(STDEV(Data!C2:C9),4)", "A10": "=SUMIF(Data!B2:B9,\"fruit\",Data!E2:E9)", "A11": "=COUNTIF(Data!B2:B9,\"veg\")", "A12": "=AVERAGEIF(Data!C2:C9,\">5\")", "A13": "=SUMIF(Data!C2:C9,\">=10\")", "A14": "=PRODUCT(Data!H2:H3)*100", "A15": "=POWER(A4,2)+SQRT(16)-ABS(-3)", "A16": "=MOD(A4*7,5)", "A17": "=INT(-A3)", "A18": "=ROUNDUP(A3,1)", "A19": "=ROUNDDOWN(A3,1)", "B1": "=INDEX(Data!A2:A9,MATCH(MAX(Data!E2:E9),Data!E2:E9,0))", "B2": "=VLOOKUP(\"fig\",Data!A2:F9,6,0)", "B3": "=VLOOKUP(\"zucchini\",Data!A2:F9,6,0)", "B4": "=IFERROR(B3,\"none\")", "B5": "=ISERROR(B3)", "B6": "=IF(ISERROR(B3),\"missing\",B3)", "B7": "=IF(AND(A1>10,OR(A4=7,A4=8)),\"big\",\"small\")", "B8": "=NOT(ISBLANK(Data!A12))", "B9": "=ISNUMBER(Data!C9)", "B10": "=ISTEXT(Data!C9)", "B11": "=Data!C9+1", "B12": "=CONCATENATE(UPPER(LEFT(Data!A2,1)),LOWER(MID(Data!A2,2,10)),\": \",A1)", "B13": "=LEN(Data!A9)&\"/\"&LEN(TRIM(Data!A9))", "B14": "=RIGHT(B1,3)&\"-\"&B2", "B15": "=MATCH(\"herb\",Data!G2:G4,0)", "B16": "=INDEX(Data!G2:H4,B15,2)*A1", "B17": "=Data!B11&\" \"&A4", "B18": "=A1/(A4-A4)", "B19": "=IFERROR(B18,-1)+B16", "C1": "=Calc!A1*2", "C2": "=SUM(Calc!A1:A3)", "C3": "=COUNTIF(Calc!A1:A5,\"<>x\")", "C4": "=Calc!B1", "C5": "=A2>A1", "C6": "=A1-A2&\"\"", "C7": "=-A4^2", "C8": "=2^3^2", "C9": "=50%*A4", "C10": "=\"3\"+Data!A11", "C11": "=SUM(Data!A2:A3)", "C12": "=Data!A2+1"}, "Calc": {"A1": "=Summary!A4+1", "A2": "=Summary!B16", "A3": "=LEN(Summary!B1)", "A4": "x", "B1": "=IF(Summary!C5,UPPER(Summary!B12),LOWER(Summary!B12))"}}}''')
CALC = json.loads(r'''{"sheets": {"Data": {"A1": "Item", "B1": "Category", "C1": "Qty", "D1": "Price", "E1": "Total", "A2": "apple", "B2": "fruit", "C2": 12, "D2": 0.5, "E2": 6, "A3": "Banana", "B3": "fruit", "C3": 7, "D3": 0.25, "E3": 1.75, "A4": "carrot", "B4": "veg", "C4": 20, "D4": 0.1, "E4": 2, "A5": "dill", "B5": "herb", "C5": 3, "D5": 1.75, "E5": 5.25, "A6": "eggplant", "B6": "veg", "C6": 4, "D6": 1.2, "E6": 4.8, "A7": "fig", "B7": "fruit", "C7": 9, "D7": 0.8, "E7": 7.2, "A8": "garlic", "B8": "herb", "C8": 15, "D8": 0.3, "E8": 4.5, "A9": "  kale  ", "B9": "veg", "C9": "6", "D9": 2, "E9": 12, "G1": "Category", "H1": "Discount", "G2": "fruit", "H2": 0.1, "G3": "herb", "H3": 0.05, "G4": "veg", "H4": 0, "F1": "Net", "F2": 5.4, "F3": 1.58, "F4": 2, "F5": 4.99, "F6": 4.8, "F7": 6.48, "F8": 4.28, "F9": 12, "A11": true, "B11": "on"}, "Summary": {"A1": 43.5, "A2": 41.53, "A3": 10, "A4": 7, "A5": 10, "A6": 0.1, "A7": 12, "A8": 9, "A9": 6.1101, "A10": 14.95, "A11": 3, "A12": 12.6, "A13": 47, "A14": 0.5000000000000001, "A15": 50, "A16": 4, "A17": -10, "A18": 10, "A19": 10, "B1": "  kale  ", "B2": 6.48, "B3": {"error": "#N/A"}, "B4": "none", "B5": true, "B6": "missing", "B7": "big", "B8": false, "B9": false, "B10": true, "B11": 7, "B12": "Apple: 43.5", "B13": "8/4", "B14": "e  -6.48", "B15": 2, "B16": 2.1750000000000003, "B17": "on 7", "B18": {"error": "#DIV/0!"}, "B19": 1.1750000000000003, "C1": 16, "C2": 18.175, "C3": 4, "C4": "apple: 43.5", "C5": false, "C6": "1.97", "C7": 49, "C8": 64, "C9": 3.5, "C10": 4, "C11": 0, "C12": {"error": "#VALUE!"}}, "Calc": {"A1": 8, "A2": 2.1750000000000003, "A3": 8, "A4": "x", "B1": "apple: 43.5"}}}''')

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

if fails:
    print("FAIL (%d)" % len(fails))
    for f in fails[:60]:
        print("  " + f)
    sys.exit(1)
print("ok")
PY
