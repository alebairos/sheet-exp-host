import json, math
from decimal import Decimal
d = json.load(open("tests/e2e/ui/checks/a_v1_ed_calc.json"))
W = {**{c: 5.56 for c in "0123456789"}, ".": 2.78, "-": 3.33, "E": 6.67, "+": 5.84}
BUDGET = 62.0
width = lambda s: sum(W[c] for c in s)
sig = lambda s: len(s.split("E")[0].replace("-", "").replace(".", "").lstrip("0"))
def dec(x, k):
    t = format(Decimal(repr(round(x, k))), "f") if k else str(int(round(x)))
    if "." in t: t = t.rstrip("0").rstrip(".")
    return t
def sci(x, k, three):
    m, ex = f"{x:.{k}e}".split("e"); ex = int(ex)
    if "." in m: m = m.rstrip("0").rstrip(".")
    return f"{m}E{'+' if ex >= 0 else '-'}{abs(ex):0{3 if three else 2}d}"
def fit(x):
    x = float(f"{x:.15g}")
    e = math.floor(math.log10(abs(x))) if x else 0
    # full General text: decimal for exponents -? .. 14, else scientific (3-digit positive exponent from 1E+16 on... per Calc)
    if e >= 15 or e < -9:
        full = sci(x, 14, e >= 16 and e < 100)
        if width(full) <= BUDGET: return full
        for k in range(14, -1, -1):
            t = sci(x, k, False)
            if width(t) <= BUDGET: return t
    exact = dec(x, 15)
    if width(exact) <= BUDGET: return exact
    best_dec = next((dec(x, k) for k in range(15, -1, -1) if width(dec(x, k)) <= BUDGET), None)
    best_sci = next((sci(x, k, False) for k in range(14, -1, -1) if width(sci(x, k, False)) <= BUDGET), None)
    if best_dec is not None and (best_sci is None or sig(best_dec) >= sig(best_sci)) and float(best_dec) != 0: return best_dec
    return best_sci
bad = [(x, s, fit(float(x))) for x, s in d["shown"] if fit(float(x)) != s]
print(len(d["shown"]) - len(bad), "of", len(d["shown"])); [print(b) for b in bad]
