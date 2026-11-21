"""Calc's parse-error rule (plan a-v1-parse-fidelity), as a scanner over a formula's tokens: None when the formula
parses (missing final ')' closed), else the Err code. Checked against every probed Calc case."""
import json, re, sys
TOK = re.compile(r"""\s+|(?P<num>(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)|(?P<str>"(?:[^"]|"")*")
  |(?P<ref>(?:'(?:[^']|'')+'!|[A-Za-z_][A-Za-z0-9_.]*!)?\$?[A-Za-z]{1,3}\$?\d+(?![A-Za-z0-9_(]))
  |(?P<call>[A-Za-z_][A-Za-z0-9_.]*(?=\s*\())|(?P<ident>[A-Za-z_][A-Za-z0-9_.]*)
  |(?P<op><>|<=|>=|[-+*/^&=<>%:(),;])""", re.X)
def rule(formula):
    s, i, toks = formula.lstrip()[1:], 0, []
    while i < len(s):
        m = TOK.match(s, i)
        if not m: return "Err:509?"
        i = m.end()
        if m.lastgroup: toks.append((m.lastgroup, m.group(m.lastgroup)))
    expect, stack, prev = True, [], None
    for k, v in toks:
        if k == "num":
            x = float(v)
            if x == float("inf") or (x == 0 and re.search(r"[1-9]", v.split("e")[0].split("E")[0])): return "Err:502"
        if k in ("num", "str", "ref", "ident"):
            if not expect: return "Err:509"
            expect = False
        elif k == "call":
            if not expect: return "Err:509"
            stack.append(["call", -1]); expect = True  # -1: its '(' is the next token
        elif v == "(":
            if prev == "call": pass
            elif not expect: return "Err:509"
            else: stack.append(["group", 0])
            expect = True
        elif v == ")":
            if not stack: return "Err:508"
            kind, n = stack.pop()
            if expect and not (kind == "call" and (n == 0 or prev in (",", ";"))): return "Err:511"
            expect = False
        elif v in (",", ";"):
            if stack and stack[-1][0] == "call": expect = True
            else: return "Err:509"
        elif v == "%":
            if expect: return "Err:510"
        else:  # a binary operator, or unary +/-
            if expect:
                if v in "+-": pass
                else: return "Err:510"
            expect = True
        if stack and v != ")" and k != "call": stack[-1][1] += 1  # tokens inside the innermost open '(' (its own '(' makes -1 -> 0)
        prev = "call" if k == "call" else v
    if expect:
        if stack: return None if (stack[-1][0] == "call" and stack[-1][1] == 0) else "Err:511"  # =SUM( is SUM()
        return "Err:520"
    return None
d = json.load(open(sys.argv[1]))
bad = 0
for c in d["cases"]:
    want = c.get("error") if c.get("error", "").startswith("Err:5") else None
    got = rule(c["formula"])
    empty_call = re.fullmatch(r"=[A-Z]+\(\)", c["formula"])  # =MAX() parses; its Err:511 is evaluation's
    if got != want and not empty_call and not (got is None and "error" in c and not c["error"].startswith("Err:5")):
        bad += 1; print("MISS", c["formula"], "rule", got, "calc", c)
print(len(d["cases"]) - bad, "of", len(d["cases"]))
