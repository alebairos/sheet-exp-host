# Intent `a-v1-text-rules`

## 1. Outcome

> Text is compared and converted unlike Calc. Observed vs LibreOffice: ="a"="A" gives TRUE (Calc FALSE, case-sensitive by default); ="é">"f" TRUE (Calc FALSE, locale order); " 5 "+0, "TRUE"+0, "$5"+0, "1,000"+0, "50%"+0 give #VALUE! (Calc 5, 1, 5, 1000, 0.5) (G21, G26, G27). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: awaiting the verdict · 3 work items · 2 bullets

## 2. What you will see

Text behaves as in LibreOffice Calc. Comparisons are case-sensitive and follow the language's order: ="a"="A" is FALSE, "a" sorts before "A" and both before "b", é sorts after e and before f, Zürich before Zuse, and punctuation sorts before digits and letters. Text that looks like an amount works in arithmetic: " 5 ", TRUE, $5, 5$, (5), 5-, 1,000, $1,000.50, 50% and 5 % give 5, 1, 5, 5, -5, -5, 1000, 1000.5, 0.5 and 0.05, in ./engine and in the browser (50% typed in a grid cell now multiplies). What Calc refuses still gives #VALUE!: 1,00, 1 000, €5, 5%%. Functions that read a number read it the same way (=ROUND("(5)",0) is -5). One visible difference remains: text Calc reads as a date or fraction ("1/2") stays #VALUE!, because dates are out of scope.

- [a-v1-text-rules/README.md](https://github.com/alebairos/sheet-exp-host/blob/ad165ba24c0fb33739e2ab9cc33da386a82d5f87/a-v1-text-rules/README.md)
- [a-v1-text-rules/today.txt](https://github.com/alebairos/sheet-exp-host/blob/ad165ba24c0fb33739e2ab9cc33da386a82d5f87/a-v1-text-rules/today.txt)
- [a-v1-text-rules/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/ad165ba24c0fb33739e2ab9cc33da386a82d5f87/a-v1-text-rules/prototype.diff)

## 3. Approach

Cause, as read in src/values and run on main (f101426). compare() orders text by Python's casefold(), so "a"="A" is TRUE and accents sort by code point ("é">"f"). to_number() accepts only a bare signed decimal, so " 5 ", "TRUE", "$5", "1,000" and "50%" are #VALUE!. Calc's defaults for a new document (case-sensitive, en-US locale collation, its own number recognition) do otherwise. a-i2 wrote those rules from memory.
The rules, from running Calc (evidence README):
- Order (< > <= >=): a three-level collation. First the letters (a..z, then þ), then accents (none < acute < grave < circumflex < ring < diaeresis < tilde...; ø, ð, æ, œ and ß count as o, d, ae, oe, ss with a mark), then case (lower before upper). Control characters (tab) sort first, then punctuation and symbols in Calc's order (pinned by 187 neighbouring pairs), then digits and letters. Format characters (soft hyphen) are ignored. Other scripts come after Latin, by code point.
- = and <> compare text exactly: e + combining acute against é is not =, yet both <= and >= are TRUE.
- Text to number: spaces (U+0020 and no-break) around and between the parts; one number (ASCII digits, ',' grouping by threes, '.', an exponent); at most one sign, before or after; one '$' before or after; '(' ')' for a negative (no sign with it); one '%' at the end; no '$' with '%'; no '$' or '%' with an exponent; TRUE/FALSE in any case (spaces only). Overflow gives 1.79769313486232E+308 without the sign. Text Calc reads as a date or fraction ("1/2", "1 1/2") stays #VALUE! here (dates out of scope).
Fix, as in the evidence prototype (about 120 lines of product code). WI 1: src/values/text_rules.py collation_key(); compare() orders text by it; = and <> in src/eval stay exact for different texts that sort equal; test_values.py's ("a","A") expectation becomes -1. WI 2: text_rules.parse_number() behind to_number(), which every function that reads a number already calls (COUNT, ROUND, ABS, MOD, INT, SQRT, POWER, LEFT, MID, IF, NOT: Calc reads them the same way, in b2); test_values.py's " 12", "12 ", "TRUE" expectations follow Calc. WI 3: tests/values/test_text_rules.py so ./test.sh keeps the rules.

Beliefs:
- ran: on main, b1 has 166 cases that differ from Calc and b2 has 173 (evidence today.txt). Settled by a_v1_tr_b1_compare.sh and a_v1_tr_b2_numbers.sh, both red on main, plus the suite check.
- ran: every expected value comes from LibreOffice Calc 26.8.1.1 headless (a_v1_tr_probe.py writes a_v1_tr_b1.json and a_v1_tr_b2.json, laid out exactly as the checks lay them out for ./engine; rerunning it reproduces both files byte for byte). Settled by b1, b2.
- ran: the rules are a model, not a list. 35,156 pairwise Calc comparisons of 188 characters gave one total order. A model written from 611 formulas then predicted 261 of 265 held-out formulas before Calc ran them. The 4 misses ("2e3$" is #VALUE!, "-1e309" gives +1.79E+308, ß against ss is an accent-level difference, = is exact) are folded in, and the checks keep those 134 held-out cases apart ("held_out"). Settled by b1, b2.
- ran: the prototype passes b1, b2 and the suite check; ./test.sh runs 82 tests, all OK; every other plan check in the repo gives what it gave on main, with one exception (next belief). Settled by the land test.
- ran, conflict: a-i2's check tests/values/checks/a2_b2_coercion.sh hand-wrote to_number("TRUE") = #VALUE! and compare("a","A") = 0. Calc gives 1 and -1. Once this lands, that old check fails on exactly those two lines. Check files cannot be edited (law 9), so this plan cannot change it. You settle it at SpecAccept: accepting means Calc wins over a-i2's two hand-written values.
- code: compare() is used only by the six operators. COUNTIF/SUMIF criteria, MATCH and VLOOKUP keep their own case-insensitive matching, which a-i5/a-i7 checked against Calc, and their checks stay green on the prototype. Settled by the land test.
- memory: the hidden suite is computed by LibreOffice headless with a new document's defaults (case-sensitive, en-US). If its files carried other options, b1 would aim at the wrong target. Settled by SpecAccept.
- memory: scripts other than Latin (Greek, Cyrillic, CJK) are ordered by code point after Latin. 8 probed pairs match; whole scripts are not claimed.

Learned from RECORD.md and the overlapping pages: a-i2 said 'text order is code-point order, not Calc's locale collation ... watch it in a-i7'; this is that. a-i2 rejected 'Python float() text conversion: Calc rejects ambiguous text', which running Calc contradicts for $, thousands, % and padding. The review's S23 (50% typed in the grid is text, so =A1*2 is #VALUE!) now computes 1. From the gate reviews of a-v1-entry-display and a-v1-parse-fidelity: state the rule, hold cases out, test edges. From a-v1-parse-fidelity's SpecReject: the files the checks run are pasted below. Overlaps: a-v1-number-text (src/values format_number) and a-v1-decimal-noise (arithmetic) touch other functions of the same files; nothing here changes how numbers print.

tests/values/checks/a_v1_tr_b1_compare.sh, in full:
```sh
#!/bin/sh
# b1 (plan a-v1-text-rules): text comparison with = <> < > <= >= matches LibreOffice's default (case-sensitive,
# locale collation). ./engine computes, in one workbook, every case of a_v1_tr_b1.json (layout: a_v1_tr_common.py):
# Calc's order of 188 single characters (187 neighbouring pairs), 117 pairs of texts in cells with all six
# operators ("a" vs "A", é vs f, Zürich vs Zuse, co-op vs coop, ß vs ss, æ vs ae, tab, soft hyphen, ...),
# 65 pairs held out (probed only after the rules were written) and 8 literal formulas (="a"="A", ="é">"f", =""<"a", ...).
# Expected values: from running LibreOffice Calc 26.8.1.1 (a_v1_tr_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_tr_common import check; check("a_v1_tr_b1.json", "b1: text compares as in Calc")'
```
tests/values/checks/a_v1_tr_b2_numbers.sh, in full:
```sh
#!/bin/sh
# b2 (plan a-v1-text-rules): text-to-number coercion in arithmetic matches LibreOffice. ./engine computes, in one
# workbook, =A+0, =-A and =A*2 for each text of a_v1_tr_b2.json in cell A (layout: a_v1_tr_common.py): 126 texts
# (padded " 5 ", TRUE/true/False, $5 5$ -$5 ($5) (5) 5-, 1,000 and 1,234.5 but not 1,00 or 1 000, 50% 50 % -5%,
# 1e3 .5 5. +5, and what stays #VALUE!: €5, 1,5, --5, 5%%, tab or no-break space), 70 held out, and 113 formulas
# with literal text (=" 5 "+0, and the functions that read numbers the same way: =ROUND("(5)",0), =COUNT("$5"), ...).
# Expected values: from running LibreOffice Calc 26.8.1.1 (a_v1_tr_probe.py), never written by hand.
set -eu
cd "$(dirname "$0")"
exec python3 -c 'from a_v1_tr_common import check; check("a_v1_tr_b2.json", "b2: text reads as a number as in Calc")'
```
tests/values/checks/a_v1_tr_common.py, in full (both checks import it):
```python
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
```
tests/values/checks/a_v1_tr_suite.sh: the same as tests/eval/checks/a_v1_ee_suite.sh, for tests/values/test_text_rules.py (the product's tests must exist, be discovered by ./test.sh, not be skipped, and pass).

- **Reuses:** compare() and to_number() as the single places the operators and functions already go through; src/eval's six comparison operators; Python's unicodedata (NFD) for accents; the probe pattern of a-v1-parse-fidelity (UNO, LibreOffice headless).
- **Removes:** casefold() text comparison and the bare-decimal-only text-to-number rule in src/values.
- **Rejected:** none recorded

## 4. Work items

### `wi-a-v1-text-rules-1`: Compare text as Calc does

Text comparisons become case-sensitive and follow Calc's language order (letters, then accents, then case), with = still exact, so ="a"="A" is FALSE and é sorts between e and f as in Calc.

Status: landed (`d45620825e46`)

**The passing review noted:** > PASS. wi-a-v1-text-rules-1 attempt 2 (1b7d8f5) reviewed against b1 / ac-tr-b1.
> 
> Evidence:
> - ac-tr-b1 (tests/values/checks/a_v1_tr_b1_compare.sh, from plan 86f21e8): "ok b1: text compares as in Calc" on the WI; on main aa2fd48 it is red with 166 cases. The WI's ./test.sh: 148 tests OK.
> - Code: src/values/__init__.py:280-284. compare() orders text by text_rules.collation_key (three levels) and returns TEXT_TIE when different texts sort equal. src/eval/__init__.py:200-201 keeps = and <> exact for TEXT_TIE. collation_data.py comes from Calc via tests/values/calc_collation_probe.py.
> - Attempt 1's failure is fixed: my 112 held-out pairs from that review, run through LibreOffice 26.8.1.1 over UNO, now give 0 differences. They cover symbols and emoji before digits, ł đ ı ŋ, fullwidth forms and ligatures.
> - New held-out set (153 pairs never shown to the implementer, Calc answers by UNO) gives 148 matches. They cover Cyrillic and Greek accents, kana and width, CJK, Arabic, Hebrew, Devanagari, IPA letters, math alphanumerics, Roman numerals, digits of other scripts, ligatures, digraphs, multi-position case against accent, currency, emoji with skin-tone modifiers and ZWJ, zero-width and no-break spaces, and dash variants. The 5 misses:
>   * 'ґ' vs 'д' (Calc <, engine >) and 'ї' vs 'й' (Calc <, engine >): Ukrainian letters outside the probed Cyrillic table fall back to code point.
>   * 'ア' vs 'い' (Calc <, engine >): katakana sorts after all hiragana rather than interleaved by sound.
>   * '❤️' vs '❤' (Calc sorts them equal, engine >): U+FE0F VARIATION SELECTOR-16 (category Mn) gets an accent weight. Calc ignores it. Emoji pasted from phones carry it.
>   * '・' vs '·' (Calc <, engine >).
>   The plan's beliefs claim no script other than Latin ("whole scripts are not claimed"), and the module's docstring names its known gaps. So these are findings, not a fail. A small follow-up could ignore variation selectors (U+FE00-FE0F) and add Ukrainian і ї є ґ to the probe.
> - Regressions: I ran all 55 tests/*/checks/*.sh on main and on the WI (CHROME=/usr/bin/chromium) and diffed. Only two changed. a_v1_tr_b1 goes red to green. tests/values/checks/a2_b2_coercion.sh now FAILs on compare('a','A'): got -1, want 0. That is the conflict the plan declared and SpecAccept accepted: Calc gives -1. COUNTIF/SUMIF, MATCH, VLOOKUP and every other check give exactly what they gave on main.
> - Speed: 20,000 text compares take 0.19 s (collation_key is lru_cached).
> - Scope: every path is under src/values, src/eval or tests/values, all in scope.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-tr-b1` | b1 | `tests/values/checks/a_v1_tr_b1_compare.sh` | red | — |

### `wi-a-v1-text-rules-2`: Read amounts in text as numbers

Text such as " 5 ", TRUE, $5, (5), 1,000 and 50% reads as a number in arithmetic and in the functions that read numbers, exactly where Calc reads it, so it no longer gives #VALUE!.

Status: landed (`7f45bdc1d17a`) · depends on `wi-a-v1-text-rules-1`

**The passing review noted:** > PASS. wi-a-v1-text-rules-2 attempt 1 (f03f26f, on main ad46068) reviewed against b2 / ac-tr-b2.
> 
> Evidence:
> - ac-tr-b2 (tests/values/checks/a_v1_tr_b2_numbers.sh, plan 86f21e8): "ok b2: text reads as a number as in Calc" on the WI; on main ad46068 it is red, 173 cases. b1 stays green. ./test.sh: 148 tests OK. ac-tr-suite is still red, as expected: it belongs to WI-3 (tests/values/test_text_rules.py).
> - Code: src/values/__init__.py:183-184. to_number() calls text_rules.parse_number(); the old ASCII regex is gone. src/values/text_rules.py:144-190 tokenises the text into one number and symbols (sign, $, parentheses, %) and applies the rules stated in the plan. TRUE/FALSE in any case with spaces around read as 1/0. The test_values.py change follows Calc (" 12", "12 ", "TRUE", "$5", "1,000", "50%").
> - Fresh held-out probe: 122 cases never shown to the implementer, with Calc answers from LibreOffice 26.8.1.1 over UNO, laid out with the plan's a_v1_tr_common.layout. They are 98 texts through =A+0, =-A and =A*2, and 24 formulas through ROUND, ROUNDUP, MOD, POWER, SQRT, INT, ABS, MID, LEFT, COUNT, SUM, MAX, MIN, AVERAGE, IF, NOT, AND and OR. Cases include "1 e3", "1,000e3", "( 5 )", "(5)%", "$(5)", "(5$)", "5$-", "$+5", "1,000.", "0,001", "1,0000", "12,345,678", "1e400", "-1e400" (Calc: +max, and *2 is #NUM!), "1e-400", "+-5", "5 -", "  -  5  ", "TRUE ", " true", "fAlSe", NBSP padding, tab, "١٢", "５", "0x1A", "Inf", "$$5", "5-%", "(5%)-", "€5", "1'000", "TRUE5", "1e3e3" and "1E+308%". Result: 118 match; main has 61 differences on the same set.
>   The 4 misses: "1/2", "3:00" and "2026-01-01" are dates, times and fractions, out of scope by the plan. ISNUMBER("5") differs only because UNO returns FALSE as 0.0 (a probe artifact).
>   The WI also fixes a main bug: Arabic-Indic "١٢" and fullwidth "５" were read as numbers through Python float(); Calc and the WI give #VALUE!.
> - Regressions: I ran all landed tests/*/checks/*.sh (CHROME=/usr/bin/chromium) on main and on the WI and diffed. a_v1_tr_b2 goes red to green. tests/values/checks/a2_b2_coercion.sh adds "FAIL to_number('TRUE'): got 1, want #VALUE!", the second half of the conflict the plan declared and SpecAccept accepted (Calc gives 1). Every other check is unchanged: COUNTIF/SUMIF, lookups, the parse, decimal and number-text checks, and the UI checks.
> 
> Findings (non-blocking):
> - An overflowing text such as "1e400" gives 1.79769313486231E+308, where Calc shows 1.79769313486232E+308. The code says this is deliberate (text_rules.py:151-155): the exact maximum double makes src/cli.py's 15-digit output crash, as it already does on main for a typed =1.7976931348623157E308. That CLI crash is pre-existing; worth a Defect for the Gm.
> - src/functions/lookup/lookup.py:30 keeps its own _NUMBER_TEXT regex for VLOOKUP and MATCH numeric-text queries. It was not changed and is out of this WI's scope, so lookup numeric text now follows different rules from arithmetic ("$5" or "1,000" as a lookup key). No check covers this; it is for the Gm if it matters.
> - Scope: src/values/__init__.py, src/values/text_rules.py and tests/values/test_values.py, all in scope.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-tr-b2` | b2 | `tests/values/checks/a_v1_tr_b2_numbers.sh` | red | — |

### `wi-a-v1-text-rules-3`: Product tests for the text rules

Adds tests/values/test_text_rules.py, run by ./test.sh, for the text order and text-to-number rules, so the product keeps Calc's behaviour.

Status: landed (`c7551f3fb394`) · depends on `wi-a-v1-text-rules-2`

**The passing review noted:** > PASS. WI e185114 adds only tests/values/test_text_rules.py (+78), inside scope tests/values. Verify rerun in a worktree of the WI and of main 36266b0 (check files identical to plan 86f21e8 for tr_*):
> - ac-tr-suite (tests/values/checks/a_v1_tr_suite.sh): WI "ok ... (4)"; main FAIL "no tests in tests/values/test_text_rules.py" (base red). ./test.sh on WI: Ran 152, OK (main 148).
> - b1/b2 (a_v1_tr_b1_compare.sh, a_v1_tr_b2_numbers.sh): still ok on WI (no product code changed).
> - Fidelity: all 88 expected values (ORDER 32 test_text_rules.py:18-30, NUMBERS 29 :34-40, OVERFLOW 2 :41, VALUE_ERRORS 25 :44-45) re-derived by a fresh LibreOffice 26.8 run through the plan's UNO probe: 88/88 match. Overflow tolerance (1.79769313486231E+308 vs 1.7976931348623157E+308, :63) is documented in the docstring and is the 15-digit print, acceptable.
> - Guarding: test file run on aa2fd48 (before WI-1) fails 3/4 (="a"="A", =" 5 "+0, ="1E400"+0); on ad46068 (WI-1 only) fails the 2 number tests. So it pins both rules.
> - a2_b2_coercion.sh fails on TRUE and compare('a','A') identically on main and WI: the conflict accepted at SpecAccept, not this WI.
> Findings for the Gm/judge (ac-tr-judge, usefulness; outside this WI's scope, not failing it):
> 1. web/grid/grid.js:74 NUMBER_TEXT/parseInput keeps "$5", "1,000", "50%", "(5)" typed in a cell as text. Arithmetic now reads them (=B1+..+B5 gives 1005.5) but =SUM(B1:B5) gives 0, as in Calc for text cells; Calc's input, though, would store 5/1000/0.5/-5 as numbers, so in the UI a user's column of $ amounts totals 0. Candidate intent: cell input recognition (web/grid, formula bar) as Calc's.
> 2. conflict (usefulness vs fidelity): =IF(A4="yes",...) with A4 "Yes" gives "no" (case-sensitive, Calc-faithful) while COUNTIF(A1:A5,"yes") gives 1; an ordinary user may find that surprising. For the human.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-tr-suite` | b1, b2 | `tests/values/checks/a_v1_tr_suite.sh` | red | — |
| `ac-tr-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | text comparison with = <> < > matches LibreOffice's default (case-sensitive, locale collation) on a set of cases computed by LibreOffice | `tests/values/checks/a_v1_tr_b1_compare.sh` —, `tests/values/checks/a_v1_tr_suite.sh` —, `judge:Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried.` — |
| not yet | b2 | text-to-number coercion in arithmetic matches LibreOffice for padded, boolean, currency, thousands-separated and percent text, computed by LibreOffice | `tests/values/checks/a_v1_tr_b2_numbers.sh` —, `tests/values/checks/a_v1_tr_suite.sh` —, `judge:Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried.` — |

## 5. Out of scope and risks

- **Out of scope:** dates and date text
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/values/**`, `exp-a:src/eval/**`, `exp-a:tests/values/**`, `exp-a:tests/eval/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-text-rules-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-text-rules-1` | `rev-a@alebairos` (passed attempt 2) |
| Implemented `wi-a-v1-text-rules-2` | `impl-a1@alebairos` |
| Reviewed `wi-a-v1-text-rules-2` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-v1-text-rules-3` | `impl-a1@alebairos` |
| Reviewed `wi-a-v1-text-rules-3` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-v1-text-rules-1`:

- `src/values/text_rules.py` +133 −0
- `src/values/collation_data.py` +127 −0
- `tests/values/calc_collation_probe.py` +127 −0 (test)
- `tests/values/checks/a_v1_tr_b2.json` +114 −0 (plan check)
- `tests/values/checks/a_v1_tr_probe.py` +83 −0 (plan check)
- `tests/values/checks/a_v1_tr_b1.json` +79 −0 (plan check)
- `tests/values/checks/a_v1_tr_common.py` +73 −0 (plan check)
- `tests/values/test_collation.py` +71 −0 (test)
- `tests/values/checks/a_v1_tr_suite.sh` +26 −0 (plan check)
- `src/values/__init__.py` +18 −2
- `tests/values/checks/a_v1_tr_b1_compare.sh` +10 −0 (plan check)
- `tests/values/checks/a_v1_tr_b2_numbers.sh` +10 −0 (plan check)
- `src/eval/__init__.py` +3 −1
- `tests/values/test_values.py` +1 −1 (test)

Files landed by `wi-a-v1-text-rules-2`:

- `src/values/text_rules.py` +59 −2
- `src/values/__init__.py` +3 −10
- `tests/values/test_values.py` +3 −1 (test)

Files landed by `wi-a-v1-text-rules-3`:

- `tests/values/test_text_rules.py` +78 −0 (test)

Landing pull request: [exp-a #41](https://github.com/alebairos/sheet-exp-a/pull/41)

## 7. The decision

**Judge:a-v1-text-rules:judge:Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried.**: A decision: show your human its options. The question: Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried.

- Pass: `cooknship decide --answer Judge:a-v1-text-rules:judge:Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried. --option pass`
- Fail, with the reason: `cooknship decide --answer Judge:a-v1-text-rules:judge:Usefulness only (not Calc fidelity): through the product as shipped, ./engine on a workbook and the browser page (python3 web/io/serve.py, /io/index.html), can an ordinary user keep a small list with names and amounts typed the way people type them (" 5 ", $5, 1,000, 50%, (5)), total and compare them, and sort or test names with IF (=IF(A1="Yes",...), names with accents and capitals), getting results that make sense to them and no unexpected #VALUE!? Answer yes or no with what you tried. --option fail --text "<reason>"`

## 8. Metrics

- Lead time: 11 h 15 min so far
- Loops: 1 (D5 review 1)
- Waste: 18 min
- Size: 358 lines (+343 −15, 11 files, ≤400; tests 282 lines); plan check files laid over by land, not in the size: +395 −0, 7 files
