#!/bin/sh
# b2: a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc.
# Contract (plan r1-engine): the engine CLI (./engine, SPEC.md) computes whole workbooks as LibreOffice Calc does.
# 1. The workbook below goes through ./engine as one file; every cell must equal Calc's answer, which LibreOffice
#    headless computed over this exact workbook (numbers within 1e-9 relative; Calc's Err:5xx kept as Calc shows it).
# 2. The product carries its own end-to-end suite: tests/e2e/engine/books/<name>.json workbooks, each with Calc's
#    answers in <name>.calc.json, and unittest tests under tests/e2e/engine that ./test.sh discovers and that pass;
#    every product workbook computes through ./engine as its .calc.json says.
# 3. Among the product's workbooks, one holds a chain of at least 100 formulas, each reading the one before
#    (the longest path of formula-to-formula references, a range reaching every formula inside it), and Calc's
#    answers for it carry an error value.
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

BOOK = json.loads(r'''{"sheets": {"Sheet1": {"A1": 1, "A2": "=A1+1", "A3": "=A2+1", "A4": "=A3+1", "A5": "=A4+1", "A6": "=A5+1", "A7": "=A6+1", "A8": "=A7+1", "A9": "=A8+1", "A10": "=A9+1", "A11": "=A10+1", "A12": "=A11+1", "A13": "=A12+1", "A14": "=A13+1", "A15": "=A14+1", "A16": "=A15+1", "A17": "=A16+1", "A18": "=A17+1", "A19": "=A18+1", "A20": "=A19+1", "A21": "=A20+1", "A22": "=A21+1", "A23": "=A22+1", "A24": "=A23+1", "A25": "=A24+1", "A26": "=A25+1", "A27": "=A26+1", "A28": "=A27+1", "A29": "=A28+1", "A30": "=A29+1", "A31": "=A30+1", "A32": "=A31+1", "A33": "=A32+1", "A34": "=A33+1", "A35": "=A34+1", "A36": "=A35+1", "A37": "=A36+1", "A38": "=A37+1", "A39": "=A38+1", "A40": "=A39/(A1-1)", "A41": "=A40+1", "A42": "=A41+1", "A43": "=A42+1", "A44": "=A43+1", "A45": "=A44+1", "A46": "=A45+1", "A47": "=A46+1", "A48": "=A47+1", "A49": "=A48+1", "A50": "=A49+1", "A51": "=A50+1", "A52": "=A51+1", "A53": "=A52+1", "A54": "=A53+1", "A55": "=A54+1", "A56": "=A55+1", "A57": "=A56+1", "A58": "=A57+1", "A59": "=A58+1", "A60": "=A59+1", "A61": "=A60+1", "A62": "=A61+1", "A63": "=A62+1", "A64": "=A63+1", "A65": "=A64+1", "A66": "=A65+1", "A67": "=A66+1", "A68": "=A67+1", "A69": "=A68+1", "A70": "=A69+1", "A71": "=A70+1", "A72": "=A71+1", "A73": "=A72+1", "A74": "=A73+1", "A75": "=A74+1", "A76": "=A75+1", "A77": "=A76+1", "A78": "=A77+1", "A79": "=A78+1", "A80": "=A79+1", "A81": "=A80+1", "A82": "=A81+1", "A83": "=A82+1", "A84": "=A83+1", "A85": "=A84+1", "A86": "=A85+1", "A87": "=A86+1", "A88": "=A87+1", "A89": "=A88+1", "A90": "=A89+1", "A91": "=A90+1", "A92": "=A91+1", "A93": "=A92+1", "A94": "=A93+1", "A95": "=A94+1", "A96": "=A95+1", "A97": "=A96+1", "A98": "=A97+1", "A99": "=A98+1", "A100": "=A99+1", "B1": "=SUM(A1:A39)", "B2": "=SUM(A1:A100)", "B3": "=COUNT(A1:A100)", "B4": "=IFERROR(A100,\"caught\")", "B5": "=ISERROR(A41)", "B6": "=A100", "B7": "=COUNTA(A1:A100)", "B8": "=MAX(A1:A39)", "B9": "=IF(ISERROR(A60),A39*2,A60)", "C1": "=C2*1+1", "C2": "=C3*1+1", "C3": "=C4*1+1", "C4": "=C5*1+1", "C5": "=C6*1+1", "C6": "=C7*1+1", "C7": "=C8*1+1", "C8": "=C9*1+1", "C9": "=C10*1+1", "C10": "=C11*1+1", "C11": "=C12*1+1", "C12": "=C13*1+1", "C13": "=C14*1+1", "C14": "=C15*1+1", "C15": "=C16*1+1", "C16": "=C17*1+1", "C17": "=C18*1+1", "C18": "=C19*1+1", "C19": "=C20*1+1", "C20": "=C21*1+1", "C21": "=C22*1+1", "C22": "=C23*1+1", "C23": "=C24*1+1", "C24": "=C25*1+1", "C25": "=C26*1+1", "C26": "=C27*1+1", "C27": "=C28*1+1", "C28": "=C29*1+1", "C29": "=C30*1+1", "C30": "=C31*1+1", "C31": "=C32*1+1", "C32": "=C33*1+1", "C33": "=C34*1+1", "C34": "=C35*1+1", "C35": "=C36*1+1", "C36": "=C37*1+1", "C37": "=C38*1+1", "C38": "=C39*1+1", "C39": "=C40*1+1", "C40": "=C41*1+1", "C41": "=C42*1+1", "C42": "=C43*1+1", "C43": "=C44*1+1", "C44": "=C45*1+1", "C45": "=C46*1+1", "C46": "=C47*1+1", "C47": "=C48*1+1", "C48": "=C49*1+1", "C49": "=C50*1+1", "C50": "=C51*1+1", "C51": "=C52*1+1", "C52": "=C53*1+1", "C53": "=C54*1+1", "C54": "=C55*1+1", "C55": "=C56*1+1", "C56": "=C57*1+1", "C57": "=C58*1+1", "C58": "=C59*1+1", "C59": "=C60*1+1", "C60": "=C61*1+1", "C61": "=C62*1+1", "C62": "=C63*1+1", "C63": "=C64*1+1", "C64": "=C65*1+1", "C65": "=C66*1+1", "C66": "=C67*1+1", "C67": "=C68*1+1", "C68": "=C69*1+1", "C69": "=C70*1+1", "C70": "=C71*1+1", "C71": "=C72*1+1", "C72": "=C73*1+1", "C73": "=C74*1+1", "C74": "=C75*1+1", "C75": "=C76*1+1", "C76": "=C77*1+1", "C77": "=C78*1+1", "C78": "=C79*1+1", "C79": "=C80*1+1", "C80": "=C81*1+1", "C81": "=C82*1+1", "C82": "=C83*1+1", "C83": "=C84*1+1", "C84": "=C85*1+1", "C85": "=C86*1+1", "C86": "=C87*1+1", "C87": "=C88*1+1", "C88": "=C89*1+1", "C89": "=C90*1+1", "C90": "=C91*1+1", "C91": "=C92*1+1", "C92": "=C93*1+1", "C93": "=C94*1+1", "C94": "=C95*1+1", "C95": "=C96*1+1", "C96": "=C97*1+1", "C97": "=C98*1+1", "C98": "=C99*1+1", "C99": "=C100*1+1", "C100": "=LEN(\"ab\")", "D1": "=C1"}, "Sheet2": {"A1": "=VLOOKUP(\"nope\",Sheet1!A1:A5,1,0)", "A2": "=UPPER(A1)", "A3": "=CONCATENATE(Sheet2!A2,\"x\")", "A4": "=UPPER(A3)", "A5": "=CONCATENATE(Sheet2!A4,\"x\")", "A6": "=UPPER(A5)", "A7": "=CONCATENATE(Sheet2!A6,\"x\")", "A8": "=UPPER(A7)", "A9": "=CONCATENATE(Sheet2!A8,\"x\")", "A10": "=UPPER(A9)", "A11": "=CONCATENATE(Sheet2!A10,\"x\")", "A12": "=UPPER(A11)", "A13": "=CONCATENATE(Sheet2!A12,\"x\")", "A14": "=UPPER(A13)", "A15": "=CONCATENATE(Sheet2!A14,\"x\")", "A16": "=UPPER(A15)", "A17": "=CONCATENATE(Sheet2!A16,\"x\")", "A18": "=UPPER(A17)", "A19": "=CONCATENATE(Sheet2!A18,\"x\")", "A20": "=UPPER(A19)", "A21": "=CONCATENATE(Sheet2!A20,\"x\")", "A22": "=UPPER(A21)", "A23": "=CONCATENATE(Sheet2!A22,\"x\")", "A24": "=UPPER(A23)", "A25": "=CONCATENATE(Sheet2!A24,\"x\")", "A26": "=UPPER(A25)", "A27": "=CONCATENATE(Sheet2!A26,\"x\")", "A28": "=UPPER(A27)", "A29": "=CONCATENATE(Sheet2!A28,\"x\")", "A30": "=UPPER(A29)", "A31": "=CONCATENATE(Sheet2!A30,\"x\")", "A32": "=UPPER(A31)", "A33": "=CONCATENATE(Sheet2!A32,\"x\")", "A34": "=UPPER(A33)", "A35": "=CONCATENATE(Sheet2!A34,\"x\")", "A36": "=UPPER(A35)", "A37": "=CONCATENATE(Sheet2!A36,\"x\")", "A38": "=UPPER(A37)", "A39": "=CONCATENATE(Sheet2!A38,\"x\")", "A40": "=UPPER(A39)", "A41": "=CONCATENATE(Sheet2!A40,\"x\")", "A42": "=UPPER(A41)", "A43": "=CONCATENATE(Sheet2!A42,\"x\")", "A44": "=UPPER(A43)", "A45": "=CONCATENATE(Sheet2!A44,\"x\")", "A46": "=UPPER(A45)", "A47": "=CONCATENATE(Sheet2!A46,\"x\")", "A48": "=UPPER(A47)", "A49": "=CONCATENATE(Sheet2!A48,\"x\")", "A50": "=UPPER(A49)", "A51": "=CONCATENATE(Sheet2!A50,\"x\")", "A52": "=UPPER(A51)", "A53": "=CONCATENATE(Sheet2!A52,\"x\")", "A54": "=UPPER(A53)", "A55": "=CONCATENATE(Sheet2!A54,\"x\")", "A56": "=UPPER(A55)", "A57": "=CONCATENATE(Sheet2!A56,\"x\")", "A58": "=UPPER(A57)", "A59": "=CONCATENATE(Sheet2!A58,\"x\")", "A60": "=UPPER(A59)", "A61": "=CONCATENATE(Sheet2!A60,\"x\")", "A62": "=UPPER(A61)", "A63": "=CONCATENATE(Sheet2!A62,\"x\")", "A64": "=UPPER(A63)", "A65": "=CONCATENATE(Sheet2!A64,\"x\")", "A66": "=UPPER(A65)", "A67": "=CONCATENATE(Sheet2!A66,\"x\")", "A68": "=UPPER(A67)", "A69": "=CONCATENATE(Sheet2!A68,\"x\")", "A70": "=UPPER(A69)", "A71": "=CONCATENATE(Sheet2!A70,\"x\")", "A72": "=UPPER(A71)", "A73": "=CONCATENATE(Sheet2!A72,\"x\")", "A74": "=UPPER(A73)", "A75": "=CONCATENATE(Sheet2!A74,\"x\")", "A76": "=UPPER(A75)", "A77": "=CONCATENATE(Sheet2!A76,\"x\")", "A78": "=UPPER(A77)", "A79": "=CONCATENATE(Sheet2!A78,\"x\")", "A80": "=UPPER(A79)", "A81": "=CONCATENATE(Sheet2!A80,\"x\")", "A82": "=UPPER(A81)", "A83": "=CONCATENATE(Sheet2!A82,\"x\")", "A84": "=UPPER(A83)", "A85": "=CONCATENATE(Sheet2!A84,\"x\")", "A86": "=UPPER(A85)", "A87": "=CONCATENATE(Sheet2!A86,\"x\")", "A88": "=UPPER(A87)", "A89": "=CONCATENATE(Sheet2!A88,\"x\")", "A90": "=UPPER(A89)", "A91": "=CONCATENATE(Sheet2!A90,\"x\")", "A92": "=UPPER(A91)", "A93": "=CONCATENATE(Sheet2!A92,\"x\")", "A94": "=UPPER(A93)", "A95": "=CONCATENATE(Sheet2!A94,\"x\")", "A96": "=UPPER(A95)", "A97": "=CONCATENATE(Sheet2!A96,\"x\")", "A98": "=UPPER(A97)", "A99": "=CONCATENATE(Sheet2!A98,\"x\")", "A100": "=UPPER(A99)", "B1": "=ISERROR(A100)", "B2": "=IFERROR(LEN(A100),0)", "C1": "start", "C2": "=IF(LEN(C1)>20,LEFT(C1,5),C1&\"+\")", "C3": "=IF(LEN(C2)>20,LEFT(C2,5),C2&\"+\")", "C4": "=IF(LEN(C3)>20,LEFT(C3,5),C3&\"+\")", "C5": "=IF(LEN(C4)>20,LEFT(C4,5),C4&\"+\")", "C6": "=IF(LEN(C5)>20,LEFT(C5,5),C5&\"+\")", "C7": "=IF(LEN(C6)>20,LEFT(C6,5),C6&\"+\")", "C8": "=IF(LEN(C7)>20,LEFT(C7,5),C7&\"+\")", "C9": "=IF(LEN(C8)>20,LEFT(C8,5),C8&\"+\")", "C10": "=IF(LEN(C9)>20,LEFT(C9,5),C9&\"+\")", "C11": "=IF(LEN(C10)>20,LEFT(C10,5),C10&\"+\")", "C12": "=IF(LEN(C11)>20,LEFT(C11,5),C11&\"+\")", "C13": "=IF(LEN(C12)>20,LEFT(C12,5),C12&\"+\")", "C14": "=IF(LEN(C13)>20,LEFT(C13,5),C13&\"+\")", "C15": "=IF(LEN(C14)>20,LEFT(C14,5),C14&\"+\")", "C16": "=IF(LEN(C15)>20,LEFT(C15,5),C15&\"+\")", "C17": "=IF(LEN(C16)>20,LEFT(C16,5),C16&\"+\")", "C18": "=IF(LEN(C17)>20,LEFT(C17,5),C17&\"+\")", "C19": "=IF(LEN(C18)>20,LEFT(C18,5),C18&\"+\")", "C20": "=IF(LEN(C19)>20,LEFT(C19,5),C19&\"+\")", "C21": "=IF(LEN(C20)>20,LEFT(C20,5),C20&\"+\")", "C22": "=IF(LEN(C21)>20,LEFT(C21,5),C21&\"+\")", "C23": "=IF(LEN(C22)>20,LEFT(C22,5),C22&\"+\")", "C24": "=IF(LEN(C23)>20,LEFT(C23,5),C23&\"+\")", "C25": "=IF(LEN(C24)>20,LEFT(C24,5),C24&\"+\")", "C26": "=IF(LEN(C25)>20,LEFT(C25,5),C25&\"+\")", "C27": "=IF(LEN(C26)>20,LEFT(C26,5),C26&\"+\")", "C28": "=IF(LEN(C27)>20,LEFT(C27,5),C27&\"+\")", "C29": "=IF(LEN(C28)>20,LEFT(C28,5),C28&\"+\")", "C30": "=IF(LEN(C29)>20,LEFT(C29,5),C29&\"+\")", "C31": "=IF(LEN(C30)>20,LEFT(C30,5),C30&\"+\")", "C32": "=IF(LEN(C31)>20,LEFT(C31,5),C31&\"+\")", "C33": "=IF(LEN(C32)>20,LEFT(C32,5),C32&\"+\")", "C34": "=IF(LEN(C33)>20,LEFT(C33,5),C33&\"+\")", "C35": "=IF(LEN(C34)>20,LEFT(C34,5),C34&\"+\")", "C36": "=IF(LEN(C35)>20,LEFT(C35,5),C35&\"+\")", "C37": "=IF(LEN(C36)>20,LEFT(C36,5),C36&\"+\")", "C38": "=IF(LEN(C37)>20,LEFT(C37,5),C37&\"+\")", "C39": "=IF(LEN(C38)>20,LEFT(C38,5),C38&\"+\")", "C40": "=IF(LEN(C39)>20,LEFT(C39,5),C39&\"+\")", "C41": "=IF(LEN(C40)>20,LEFT(C40,5),C40&\"+\")", "C42": "=IF(LEN(C41)>20,LEFT(C41,5),C41&\"+\")", "C43": "=IF(LEN(C42)>20,LEFT(C42,5),C42&\"+\")", "C44": "=IF(LEN(C43)>20,LEFT(C43,5),C43&\"+\")", "C45": "=IF(LEN(C44)>20,LEFT(C44,5),C44&\"+\")", "C46": "=IF(LEN(C45)>20,LEFT(C45,5),C45&\"+\")", "C47": "=IF(LEN(C46)>20,LEFT(C46,5),C46&\"+\")", "C48": "=IF(LEN(C47)>20,LEFT(C47,5),C47&\"+\")", "C49": "=IF(LEN(C48)>20,LEFT(C48,5),C48&\"+\")", "C50": "=IF(LEN(C49)>20,LEFT(C49,5),C49&\"+\")", "C51": "=IF(LEN(C50)>20,LEFT(C50,5),C50&\"+\")", "C52": "=IF(LEN(C51)>20,LEFT(C51,5),C51&\"+\")", "C53": "=IF(LEN(C52)>20,LEFT(C52,5),C52&\"+\")", "C54": "=IF(LEN(C53)>20,LEFT(C53,5),C53&\"+\")", "C55": "=IF(LEN(C54)>20,LEFT(C54,5),C54&\"+\")", "C56": "=IF(LEN(C55)>20,LEFT(C55,5),C55&\"+\")", "C57": "=IF(LEN(C56)>20,LEFT(C56,5),C56&\"+\")", "C58": "=IF(LEN(C57)>20,LEFT(C57,5),C57&\"+\")", "C59": "=IF(LEN(C58)>20,LEFT(C58,5),C58&\"+\")", "C60": "=IF(LEN(C59)>20,LEFT(C59,5),C59&\"+\")", "C61": "=IF(LEN(C60)>20,LEFT(C60,5),C60&\"+\")", "C62": "=IF(LEN(C61)>20,LEFT(C61,5),C61&\"+\")", "C63": "=IF(LEN(C62)>20,LEFT(C62,5),C62&\"+\")", "C64": "=IF(LEN(C63)>20,LEFT(C63,5),C63&\"+\")", "C65": "=IF(LEN(C64)>20,LEFT(C64,5),C64&\"+\")", "C66": "=IF(LEN(C65)>20,LEFT(C65,5),C65&\"+\")", "C67": "=IF(LEN(C66)>20,LEFT(C66,5),C66&\"+\")", "C68": "=IF(LEN(C67)>20,LEFT(C67,5),C67&\"+\")", "C69": "=IF(LEN(C68)>20,LEFT(C68,5),C68&\"+\")", "C70": "=IF(LEN(C69)>20,LEFT(C69,5),C69&\"+\")", "C71": "=IF(LEN(C70)>20,LEFT(C70,5),C70&\"+\")", "C72": "=IF(LEN(C71)>20,LEFT(C71,5),C71&\"+\")", "C73": "=IF(LEN(C72)>20,LEFT(C72,5),C72&\"+\")", "C74": "=IF(LEN(C73)>20,LEFT(C73,5),C73&\"+\")", "C75": "=IF(LEN(C74)>20,LEFT(C74,5),C74&\"+\")", "C76": "=IF(LEN(C75)>20,LEFT(C75,5),C75&\"+\")", "C77": "=IF(LEN(C76)>20,LEFT(C76,5),C76&\"+\")", "C78": "=IF(LEN(C77)>20,LEFT(C77,5),C77&\"+\")", "C79": "=IF(LEN(C78)>20,LEFT(C78,5),C78&\"+\")", "C80": "=IF(LEN(C79)>20,LEFT(C79,5),C79&\"+\")", "C81": "=IF(LEN(C80)>20,LEFT(C80,5),C80&\"+\")", "C82": "=IF(LEN(C81)>20,LEFT(C81,5),C81&\"+\")", "C83": "=IF(LEN(C82)>20,LEFT(C82,5),C82&\"+\")", "C84": "=IF(LEN(C83)>20,LEFT(C83,5),C83&\"+\")", "C85": "=IF(LEN(C84)>20,LEFT(C84,5),C84&\"+\")", "C86": "=IF(LEN(C85)>20,LEFT(C85,5),C85&\"+\")", "C87": "=IF(LEN(C86)>20,LEFT(C86,5),C86&\"+\")", "C88": "=IF(LEN(C87)>20,LEFT(C87,5),C87&\"+\")", "C89": "=IF(LEN(C88)>20,LEFT(C88,5),C88&\"+\")", "C90": "=IF(LEN(C89)>20,LEFT(C89,5),C89&\"+\")", "C91": "=IF(LEN(C90)>20,LEFT(C90,5),C90&\"+\")", "C92": "=IF(LEN(C91)>20,LEFT(C91,5),C91&\"+\")", "C93": "=IF(LEN(C92)>20,LEFT(C92,5),C92&\"+\")", "C94": "=IF(LEN(C93)>20,LEFT(C93,5),C93&\"+\")", "C95": "=IF(LEN(C94)>20,LEFT(C94,5),C94&\"+\")", "C96": "=IF(LEN(C95)>20,LEFT(C95,5),C95&\"+\")", "C97": "=IF(LEN(C96)>20,LEFT(C96,5),C96&\"+\")", "C98": "=IF(LEN(C97)>20,LEFT(C97,5),C97&\"+\")", "C99": "=IF(LEN(C98)>20,LEFT(C98,5),C98&\"+\")", "C100": "=IF(LEN(C99)>20,LEFT(C99,5),C99&\"+\")", "D1": "=C100", "D2": "=Sheet1!A100&\"\"", "D3": "=Sheet1!C1+Sheet1!A39"}}}''')
CALC = json.loads(r'''{"sheets": {"Sheet1": {"A1": 1, "A2": 2, "A3": 3, "A4": 4, "A5": 5, "A6": 6, "A7": 7, "A8": 8, "A9": 9, "A10": 10, "A11": 11, "A12": 12, "A13": 13, "A14": 14, "A15": 15, "A16": 16, "A17": 17, "A18": 18, "A19": 19, "A20": 20, "A21": 21, "A22": 22, "A23": 23, "A24": 24, "A25": 25, "A26": 26, "A27": 27, "A28": 28, "A29": 29, "A30": 30, "A31": 31, "A32": 32, "A33": 33, "A34": 34, "A35": 35, "A36": 36, "A37": 37, "A38": 38, "A39": 39, "A40": {"error": "#DIV/0!"}, "A41": {"error": "#DIV/0!"}, "A42": {"error": "#DIV/0!"}, "A43": {"error": "#DIV/0!"}, "A44": {"error": "#DIV/0!"}, "A45": {"error": "#DIV/0!"}, "A46": {"error": "#DIV/0!"}, "A47": {"error": "#DIV/0!"}, "A48": {"error": "#DIV/0!"}, "A49": {"error": "#DIV/0!"}, "A50": {"error": "#DIV/0!"}, "A51": {"error": "#DIV/0!"}, "A52": {"error": "#DIV/0!"}, "A53": {"error": "#DIV/0!"}, "A54": {"error": "#DIV/0!"}, "A55": {"error": "#DIV/0!"}, "A56": {"error": "#DIV/0!"}, "A57": {"error": "#DIV/0!"}, "A58": {"error": "#DIV/0!"}, "A59": {"error": "#DIV/0!"}, "A60": {"error": "#DIV/0!"}, "A61": {"error": "#DIV/0!"}, "A62": {"error": "#DIV/0!"}, "A63": {"error": "#DIV/0!"}, "A64": {"error": "#DIV/0!"}, "A65": {"error": "#DIV/0!"}, "A66": {"error": "#DIV/0!"}, "A67": {"error": "#DIV/0!"}, "A68": {"error": "#DIV/0!"}, "A69": {"error": "#DIV/0!"}, "A70": {"error": "#DIV/0!"}, "A71": {"error": "#DIV/0!"}, "A72": {"error": "#DIV/0!"}, "A73": {"error": "#DIV/0!"}, "A74": {"error": "#DIV/0!"}, "A75": {"error": "#DIV/0!"}, "A76": {"error": "#DIV/0!"}, "A77": {"error": "#DIV/0!"}, "A78": {"error": "#DIV/0!"}, "A79": {"error": "#DIV/0!"}, "A80": {"error": "#DIV/0!"}, "A81": {"error": "#DIV/0!"}, "A82": {"error": "#DIV/0!"}, "A83": {"error": "#DIV/0!"}, "A84": {"error": "#DIV/0!"}, "A85": {"error": "#DIV/0!"}, "A86": {"error": "#DIV/0!"}, "A87": {"error": "#DIV/0!"}, "A88": {"error": "#DIV/0!"}, "A89": {"error": "#DIV/0!"}, "A90": {"error": "#DIV/0!"}, "A91": {"error": "#DIV/0!"}, "A92": {"error": "#DIV/0!"}, "A93": {"error": "#DIV/0!"}, "A94": {"error": "#DIV/0!"}, "A95": {"error": "#DIV/0!"}, "A96": {"error": "#DIV/0!"}, "A97": {"error": "#DIV/0!"}, "A98": {"error": "#DIV/0!"}, "A99": {"error": "#DIV/0!"}, "A100": {"error": "#DIV/0!"}, "B1": 780, "B2": {"error": "#DIV/0!"}, "B3": 39, "B4": "caught", "B5": true, "B6": {"error": "#DIV/0!"}, "B7": 100, "B8": 39, "B9": 78, "C1": 101, "C2": 100, "C3": 99, "C4": 98, "C5": 97, "C6": 96, "C7": 95, "C8": 94, "C9": 93, "C10": 92, "C11": 91, "C12": 90, "C13": 89, "C14": 88, "C15": 87, "C16": 86, "C17": 85, "C18": 84, "C19": 83, "C20": 82, "C21": 81, "C22": 80, "C23": 79, "C24": 78, "C25": 77, "C26": 76, "C27": 75, "C28": 74, "C29": 73, "C30": 72, "C31": 71, "C32": 70, "C33": 69, "C34": 68, "C35": 67, "C36": 66, "C37": 65, "C38": 64, "C39": 63, "C40": 62, "C41": 61, "C42": 60, "C43": 59, "C44": 58, "C45": 57, "C46": 56, "C47": 55, "C48": 54, "C49": 53, "C50": 52, "C51": 51, "C52": 50, "C53": 49, "C54": 48, "C55": 47, "C56": 46, "C57": 45, "C58": 44, "C59": 43, "C60": 42, "C61": 41, "C62": 40, "C63": 39, "C64": 38, "C65": 37, "C66": 36, "C67": 35, "C68": 34, "C69": 33, "C70": 32, "C71": 31, "C72": 30, "C73": 29, "C74": 28, "C75": 27, "C76": 26, "C77": 25, "C78": 24, "C79": 23, "C80": 22, "C81": 21, "C82": 20, "C83": 19, "C84": 18, "C85": 17, "C86": 16, "C87": 15, "C88": 14, "C89": 13, "C90": 12, "C91": 11, "C92": 10, "C93": 9, "C94": 8, "C95": 7, "C96": 6, "C97": 5, "C98": 4, "C99": 3, "C100": 2, "D1": 101}, "Sheet2": {"A1": {"error": "#N/A"}, "A2": {"error": "#N/A"}, "A3": {"error": "#N/A"}, "A4": {"error": "#N/A"}, "A5": {"error": "#N/A"}, "A6": {"error": "#N/A"}, "A7": {"error": "#N/A"}, "A8": {"error": "#N/A"}, "A9": {"error": "#N/A"}, "A10": {"error": "#N/A"}, "A11": {"error": "#N/A"}, "A12": {"error": "#N/A"}, "A13": {"error": "#N/A"}, "A14": {"error": "#N/A"}, "A15": {"error": "#N/A"}, "A16": {"error": "#N/A"}, "A17": {"error": "#N/A"}, "A18": {"error": "#N/A"}, "A19": {"error": "#N/A"}, "A20": {"error": "#N/A"}, "A21": {"error": "#N/A"}, "A22": {"error": "#N/A"}, "A23": {"error": "#N/A"}, "A24": {"error": "#N/A"}, "A25": {"error": "#N/A"}, "A26": {"error": "#N/A"}, "A27": {"error": "#N/A"}, "A28": {"error": "#N/A"}, "A29": {"error": "#N/A"}, "A30": {"error": "#N/A"}, "A31": {"error": "#N/A"}, "A32": {"error": "#N/A"}, "A33": {"error": "#N/A"}, "A34": {"error": "#N/A"}, "A35": {"error": "#N/A"}, "A36": {"error": "#N/A"}, "A37": {"error": "#N/A"}, "A38": {"error": "#N/A"}, "A39": {"error": "#N/A"}, "A40": {"error": "#N/A"}, "A41": {"error": "#N/A"}, "A42": {"error": "#N/A"}, "A43": {"error": "#N/A"}, "A44": {"error": "#N/A"}, "A45": {"error": "#N/A"}, "A46": {"error": "#N/A"}, "A47": {"error": "#N/A"}, "A48": {"error": "#N/A"}, "A49": {"error": "#N/A"}, "A50": {"error": "#N/A"}, "A51": {"error": "#N/A"}, "A52": {"error": "#N/A"}, "A53": {"error": "#N/A"}, "A54": {"error": "#N/A"}, "A55": {"error": "#N/A"}, "A56": {"error": "#N/A"}, "A57": {"error": "#N/A"}, "A58": {"error": "#N/A"}, "A59": {"error": "#N/A"}, "A60": {"error": "#N/A"}, "A61": {"error": "#N/A"}, "A62": {"error": "#N/A"}, "A63": {"error": "#N/A"}, "A64": {"error": "#N/A"}, "A65": {"error": "#N/A"}, "A66": {"error": "#N/A"}, "A67": {"error": "#N/A"}, "A68": {"error": "#N/A"}, "A69": {"error": "#N/A"}, "A70": {"error": "#N/A"}, "A71": {"error": "#N/A"}, "A72": {"error": "#N/A"}, "A73": {"error": "#N/A"}, "A74": {"error": "#N/A"}, "A75": {"error": "#N/A"}, "A76": {"error": "#N/A"}, "A77": {"error": "#N/A"}, "A78": {"error": "#N/A"}, "A79": {"error": "#N/A"}, "A80": {"error": "#N/A"}, "A81": {"error": "#N/A"}, "A82": {"error": "#N/A"}, "A83": {"error": "#N/A"}, "A84": {"error": "#N/A"}, "A85": {"error": "#N/A"}, "A86": {"error": "#N/A"}, "A87": {"error": "#N/A"}, "A88": {"error": "#N/A"}, "A89": {"error": "#N/A"}, "A90": {"error": "#N/A"}, "A91": {"error": "#N/A"}, "A92": {"error": "#N/A"}, "A93": {"error": "#N/A"}, "A94": {"error": "#N/A"}, "A95": {"error": "#N/A"}, "A96": {"error": "#N/A"}, "A97": {"error": "#N/A"}, "A98": {"error": "#N/A"}, "A99": {"error": "#N/A"}, "A100": {"error": "#N/A"}, "B1": true, "B2": 0, "C1": "start", "C2": "start+", "C3": "start++", "C4": "start+++", "C5": "start++++", "C6": "start+++++", "C7": "start++++++", "C8": "start+++++++", "C9": "start++++++++", "C10": "start+++++++++", "C11": "start++++++++++", "C12": "start+++++++++++", "C13": "start++++++++++++", "C14": "start+++++++++++++", "C15": "start++++++++++++++", "C16": "start+++++++++++++++", "C17": "start++++++++++++++++", "C18": "start", "C19": "start+", "C20": "start++", "C21": "start+++", "C22": "start++++", "C23": "start+++++", "C24": "start++++++", "C25": "start+++++++", "C26": "start++++++++", "C27": "start+++++++++", "C28": "start++++++++++", "C29": "start+++++++++++", "C30": "start++++++++++++", "C31": "start+++++++++++++", "C32": "start++++++++++++++", "C33": "start+++++++++++++++", "C34": "start++++++++++++++++", "C35": "start", "C36": "start+", "C37": "start++", "C38": "start+++", "C39": "start++++", "C40": "start+++++", "C41": "start++++++", "C42": "start+++++++", "C43": "start++++++++", "C44": "start+++++++++", "C45": "start++++++++++", "C46": "start+++++++++++", "C47": "start++++++++++++", "C48": "start+++++++++++++", "C49": "start++++++++++++++", "C50": "start+++++++++++++++", "C51": "start++++++++++++++++", "C52": "start", "C53": "start+", "C54": "start++", "C55": "start+++", "C56": "start++++", "C57": "start+++++", "C58": "start++++++", "C59": "start+++++++", "C60": "start++++++++", "C61": "start+++++++++", "C62": "start++++++++++", "C63": "start+++++++++++", "C64": "start++++++++++++", "C65": "start+++++++++++++", "C66": "start++++++++++++++", "C67": "start+++++++++++++++", "C68": "start++++++++++++++++", "C69": "start", "C70": "start+", "C71": "start++", "C72": "start+++", "C73": "start++++", "C74": "start+++++", "C75": "start++++++", "C76": "start+++++++", "C77": "start++++++++", "C78": "start+++++++++", "C79": "start++++++++++", "C80": "start+++++++++++", "C81": "start++++++++++++", "C82": "start+++++++++++++", "C83": "start++++++++++++++", "C84": "start+++++++++++++++", "C85": "start++++++++++++++++", "C86": "start", "C87": "start+", "C88": "start++", "C89": "start+++", "C90": "start++++", "C91": "start+++++", "C92": "start++++++", "C93": "start+++++++", "C94": "start++++++++", "C95": "start+++++++++", "C96": "start++++++++++", "C97": "start+++++++++++", "C98": "start++++++++++++", "C99": "start+++++++++++++", "C100": "start++++++++++++++", "D1": "start++++++++++++++", "D2": {"error": "#DIV/0!"}, "D3": 140}}}''')

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

if fails:
    print("FAIL (%d)" % len(fails))
    for f in fails[:60]:
        print("  " + f)
    sys.exit(1)
print("ok")
PY
