"""Shared by the a-v1-text-rules checks: lay the cases out in one workbook, run ./engine once, compare with Calc.

b1 (a_v1_tr_b1.json): "order" is Calc's order of 188 single characters (from 35,156 pairwise Calc comparisons):
each neighbouring pair must compare < in ./engine. "pairs" and "held_out": [a, b, r], texts a and b in cells
T!A, T!B and the six operators =A=B, =A<B, =A>B, =A<>B, =A<=B, =A>=B, whose Calc results r records as < = or >, or ~: not
identical (= FALSE) yet sorting equal (<= and >= TRUE), as for e + combining acute against é.
b2 (a_v1_tr_b2.json): "texts" and "held_out": [text, [=A+0, =-A, =A*2]], the text in cell N!A, Calc's results.
"formulas" (both files): [formula, Calc's result] in a cell of their own. Numbers within 1e-9 (relative);
text, booleans and errors exact. "held_out" cases were probed only after the rules were written.
"""
import json, os, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
OPS = ["=", "<", ">", "<>", "<=", ">="]
REL = {"<": [False, True, False, True, True, False], "=": [True, False, False, False, True, True],
       ">": [False, False, True, True, False, True], "~": [False, False, False, True, True, True]}

def _rows(d):
    """b1's comparison rows: neighbours in Calc's order, then the pairs. A text starting with '=' cannot be a
    cell (the workbook reads it as a formula), so those neighbours are literal formulas in "formulas"."""
    order = d.get("order", "")
    adj = [[a, b, "<"] for a, b in zip(order, order[1:]) if "=" not in (a, b)]
    return adj + d.get("pairs", []) + d.get("held_out", []) if "order" in d else []

def layout(d):
    """The workbook for data d, and fill(results) that writes Calc's results into d (only the probe uses it)."""
    s, slots = {"T": {}, "N": {}, "F": {}}, []
    for i, case in enumerate(_rows(d)):
        r = i + 1; s["T"]["A%d" % r], s["T"]["B%d" % r] = case[0], case[1]
        for j, op in enumerate(OPS): s["T"]["%s%d" % ("CDEFGH"[j], r)] = "=A%d%sB%d" % (r, op, r)
        slots.append(("T", r, case))
    for i, case in enumerate(d.get("texts", []) + d.get("held_out", []) if "texts" in d else []):
        r = i + 1; s["N"]["A%d" % r] = case[0]
        s["N"]["B%d" % r], s["N"]["C%d" % r], s["N"]["D%d" % r] = "=A%d+0" % r, "=-A%d" % r, "=A%d*2" % r
        slots.append(("N", r, case))
    for i, case in enumerate(d.get("formulas", [])):
        s["F"]["A%d" % (i + 1)] = case[0]; slots.append(("F", i + 1, case))
    def fill(res):
        for sheet, r, case in slots:
            if sheet == "T":
                got = [res["T!%s%d" % (c, r)] for c in "CDEFGH"]
                rel = [k for k, v in REL.items() if v == got]
                if len(rel) != 1: raise SystemExit("Calc's six results disagree for %r: %r" % (case[:2], got))
                case[2] = rel[0]
            elif sheet == "N": case[1] = [res["N!%s%d" % (c, r)] for c in "BCD"]
            else: case[1] = res["F!A%d" % r]
    return {"sheets": s}, fill

def same(got, want):
    if isinstance(want, float) and not isinstance(want, bool):
        return type(got) in (int, float) and not isinstance(got, bool) and abs(got - want) <= 1e-9 * max(1.0, abs(want))
    return got == want

def check(name, label):
    d = json.load(open(os.path.join(HERE, name)))
    book, _ = layout(d)
    p = subprocess.run([os.path.join(ROOT, "engine"), "-"], input=json.dumps(book), capture_output=True, text=True,
                       cwd=ROOT, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"), timeout=300)
    if p.returncode: sys.exit("FAIL ./engine exited %d: %s" % (p.returncode, p.stderr.strip()[-300:]))
    out, fails = json.loads(p.stdout)["sheets"], []
    def at(sheet, ref): return out[sheet].get(ref)
    for i, case in enumerate(_rows(d)):
        got = [at("T", "%s%d" % (c, i + 1)) for c in "CDEFGH"]
        if got != REL[case[2]]: fails.append("%r vs %r: Calc says %s, ./engine gives %s" % (case[0], case[1], case[2], dict(zip(OPS, got))))
    for i, (text, want) in enumerate(d.get("texts", []) + d.get("held_out", []) if "texts" in d else []):
        got = [at("N", "%s%d" % (c, i + 1)) for c in "BCD"]
        if not all(same(g, w) for g, w in zip(got, want)): fails.append("text %r: +0, -x, *2 give %s, Calc gives %s" % (text, got, want))
    for i, (f, want) in enumerate(d.get("formulas", [])):
        got = at("F", "A%d" % (i + 1))
        if not same(got, want): fails.append("%s gives %s, Calc gives %s" % (f, json.dumps(got), json.dumps(want)))
    for f in fails: print("FAIL " + f)
    print("%s: %d cases differ from Calc" % (label, len(fails)) if fails else "ok " + label)
    sys.exit(1 if fails else 0)
