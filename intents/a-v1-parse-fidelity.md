# Intent `a-v1-parse-fidelity`

## 1. Outcome

> Formulas Calc accepts fail here, and malformed ones give the wrong error. Observed vs LibreOffice: = SUM( A1 : A2 ) gives #VALUE! (Calc 3); =SUM( 'My Sheet'!A1 : A2 ) #VALUE! (Calc 11); =SUM(S2!A1:S2!A2) #VALUE! (Calc 7); =SUM(1,2 #VALUE! (Calc 3); =(1+ and =1+*2 give #VALUE! (Calc Err:511, Err:510); =1E400 #VALUE! (Calc Err:502); =MAX() 0 and =MEDIAN() #VALUE! (Calc Err:511) (G24, G25; prior S15, S24). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: in work · 3 work items · 2 bullets

## 2. What you will see

Formulas that LibreOffice Calc accepts work here too: spaces anywhere between tokens (= SUM( A1 : A2 )), a sheet named on both ends of a range (=SUM(S2!A1:S2!A2)), and a forgotten closing parenthesis (=SUM(1,2 gives 3). Broken formulas show Calc's specific codes instead of a generic #VALUE!: =(1+ is Err:511, =1+*2 Err:510, =1 2 Err:509, an extra ')' Err:508, =1E400 Err:502. Calling a function with no arguments behaves as in Calc (=MAX() is Err:511, =SUM() is 0) instead of giving 0 or crashing the engine (=ROUND()).

- [a-v1-parse-fidelity/README.md](https://github.com/alebairos/sheet-exp-host/blob/d29e82a28f25828171bd754a3f49df9eda37f186/a-v1-parse-fidelity/README.md)
- [a-v1-parse-fidelity/rule_model.py](https://github.com/alebairos/sheet-exp-host/blob/d29e82a28f25828171bd754a3f49df9eda37f186/a-v1-parse-fidelity/rule_model.py)

## 3. Approach

Cause, as read in the code and run on main. The tokenizer does not skip spaces between tokens (= SUM( A1 : A2 ) fails). A range's second end cannot carry a sheet (S2!A1:S2!A2), and a range written 'Sheet'!A1 : A2 with spaces fails. The parser requires every parenthesis to be closed, while Calc closes them at the end of the formula. Any ParseError becomes #VALUE!, where Calc reports a specific code (Err:508 bracketing, Err:509 operator missing, Err:510 variable missing, Err:511 missing variable, Err:520 internal syntax) and =1E400 / =1E-400 give Err:502. Empty calls go to the registered function with no arguments: MAX() is 0 and ROUND() crashes with a Python TypeError, where Calc gives Err:511 except for its variadic sums (SUM, COUNT, COUNTA, PRODUCT: 0; AVERAGE: #DIV/0!; CONCATENATE: "").
Fix. WI 1 (accept what Calc accepts, src/parser): skip whitespace between tokens (not inside strings or sheet names), let a range's second end name the same sheet (S2!A1:S2!A2), and close open parentheses at the end of the formula. WI 2 (Calc's codes, src/parser + src/eval + src/recalc): ParseError carries Calc's code, by this rule, read left to right (the evidence's rule_model.py implements it and matches all 85 Calc cases). An unmatched ')' is Err:508. Two operands side by side (=1 2, =1 (2), =(2)3, =SUM(1 2)) are Err:509. A binary operator where an operand is expected (=*2, =1+*2, =1*/2, =&1) is Err:510, while unary + and - are allowed there (=1++2 is 3). If the formula ends where an operand is expected, it is Err:511 inside an open '(' (=(1+, =1+(, =SUM(1,, =IF(1,2,, =(), =(((), except an empty open call (=SUM( computes as SUM()), and Err:520 at top level (=1+, =-, =+, =A1:, =1<>, =(1+2)+). Otherwise missing final ')' are closed (=(1, =((1+2), =SUM(A1:A2). recalc stores the code as that cell's error instead of #VALUE!. A number literal outside the double range gives Err:502. In src/eval's _call, a call with no arguments gives Err:511 unless the function is one of the variadic ones whose empty value Calc computes (the table above, from the probe), so ROUND() no longer crashes. WI 3: tests/parser/test_parse_fidelity.py.

Beliefs:
- ran: on main every accepted-formula case that differs (9) and the malformed/empty cases that differ (57 of 71 since the replan) fail (#VALUE!, 0, or a TypeError crash for =ROUND() and =ABS()). Settled by a_v1_pf_b1_accept.sh and a_v1_pf_b2_errors.sh, both red on main, each case run alone so one crash cannot hide the others.
- ran: LibreOffice Calc 26.8.1.1 headless (a_v1_pf_probe.py, read from a_v1_pf_calc.json, 45 cases; Excel-style sheet references were translated only to enter them through Calc's API): the accepted forms compute (3, 11, 7, 9, 'one'). =(1+ is Err:511, but =1+ is Err:520; =1+*2 and =*2 are Err:510; =1 2 and =A1 A2 are Err:509; =) and extra ')' are Err:508; =SUM( is 0; =1E400 and =1E-400 are Err:502; =1++2 is 3; and the empty calls as listed. Settled by b1 and b2.
- ran: the parse-error rule above. The first plan had only a list. The gate review probed 27 held-out malformed forms and stated the rule. The replan re-ran Calc on those and 13 more (40 held out, 85 cases in all, a_v1_pf_calc.json), and a 60-line scanner of the rule (evidence rule_model.py) reproduces all 85. Settled by b2, which now holds all 71 malformed and empty-call cases.
- ran (corrected in the replan): =SUM(1, is Err:511 in Calc, not a value; =(1 is 1 and =((1+2) is 3. tests/parser/test_parser.py's test_parse_errors expects ParseError for '=(1' (Calc computes it, so that expectation goes), for '=SUM(1,' (still malformed, now carrying Err:511) and for '=1+' (Err:520). The WI updates those expectations to Calc's. Settled by b2 and the land test.
- human: array literals and whole-column references stay out (intent's out of scope).

Replan (gate review 1 of 2): the rule is stated, the wrong =SUM(1, belief fixed, and b2 holds 40 held-out Calc cases. This follows the lesson from a-v1-entry-display's review: pin the rule, not the list it was read from.
Learned from RECORD.md and the overlapping pages: a-i1's reviewer noted '=A1:Sheet2!B2 and whole-column ranges are ParseErrors'; a-i3 and a-i4 noted parse failures give #VALUE! where Calc gives Err:5xx, and asked to pin it when the hidden suite's parse-error cases are looked at. This plan pins it from Calc itself. The review's S24 (spaces) and S15 (=(1+) are b1/b2's first cases. The Err:5xx naming decision stays as every earlier intent kept it (Calc's codes; a-v1-error-help explains them in the UI). The =ROUND() crash I found while planning a-v1-error-help is covered here (empty calls). Overlap: a-v1-engine-failure also changes parse() (the 8192-token Err:512 after a successful parse) and a-v1-eval-edges and a-v1-decimal-noise change src/eval; whichever lands later carries both.

Resubmitted unchanged after SpecReject (the delegate could not read a_v1_pf_common.py from git). Same plan commit 4793976; on today's main (f101426, after cli-input and eval-edges landed) b1 is still red on 9 cases, b2 on 57, the suite red. The gate's held-out corners go into WI 3's product test with Calc's answers: =% and =1+% are Err:520, =A1(2) is Err:509, =1:2 is #VALUE!, =SUM(,1) is 1 and =MAX(,) is 0.

tests/parser/checks/a_v1_pf_common.py, in full (b1 runs check(0, 14, ...), b2 the other 71 cases; each case alone in Sheet1!C1 through ./engine, compared with Calc's stored result: numbers within 1e-9, errors and text exact):

```python
"""Shared by the a-v1-parse-fidelity checks: ./engine on the probe's formulas, compared with Calc's results."""
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
CALC = json.load(open(os.path.join(HERE, "a_v1_pf_calc.json")))


def engine_cell(formula):
    """./engine on the probe's data with `formula` in Sheet1!C1: its result, or a FAIL text when ./engine fails."""
    book = {"sheets": {k: dict(v) for k, v in CALC["data"].items()}}
    book["sheets"]["Sheet1"]["C1"] = formula
    p = subprocess.run([os.path.join(ROOT, "engine"), "-"], input=json.dumps(book), capture_output=True, text=True,
                       cwd=ROOT, env=dict(os.environ, PYTHONDONTWRITEBYTECODE="1"), timeout=60)
    if p.returncode != 0:
        return "./engine exited %d: %s" % (p.returncode, (p.stderr.strip().splitlines() or [""])[-1][:120])
    return json.loads(p.stdout)["sheets"]["Sheet1"].get("C1")


def check(lo, hi, ok):
    """Cases lo..hi-1 of CALC, each alone in Sheet1!C1 next to the probe's data, against Calc's result."""
    fails = []
    for c in CALC["cases"][lo:hi]:
        got = engine_cell(c["formula"])
        if "number" in c: good = isinstance(got, (int, float)) and not isinstance(got, bool) and abs(got - c["number"]) <= 1e-9
        elif "text" in c: good = got == c["text"]
        else: good = got == {"error": c["error"]}
        if not good: fails.append("%s gives %s, Calc gives %s" % (c["formula"], json.dumps(got), json.dumps({k: v for k, v in c.items() if k != "formula"})))
    for f in fails: print("FAIL " + f)
    if not fails: print("ok " + ok)
    sys.exit(1 if fails else 0)
```

- **Reuses:** The tokenizer and recursive-descent parser, ParseError (now carrying a code), recalc's per-formula error storage, src/eval's _call and the registered functions.
- **Removes:** The blanket #VALUE! for every parse failure, and the crash on empty calls to fixed-arity functions.
- **Rejected:** Mapping every parse error to one code (Err:509 or Err:511): Calc distinguishes them and the hidden suite is computed by Calc. Checking argument counts inside each function: src/functions is outside this scope, and one rule in _call covers all 40. Accepting array literals or whole-column references: out of scope.

## 4. Work items

### `wi-a-v1-parse-fidelity-1`: Accept what Calc accepts

The parser skips spaces between tokens, lets both ends of a range name the sheet, and closes open parentheses at the end of the formula, so formulas Calc computes compute here too.

Status: landed (`20a41d6a3891`)

**The passing review noted:** > Pass, with one CONFLICT for the human/Gm (below). The WI cannot settle it: check edits are dropped.
> 
> Verify rerun on 0773715 (parent: current main 4367e6e), with plan 4793976's check files copied in. ac-pf-b1 tests/parser/checks/a_v1_pf_b1_accept.sh: "ok b1: 14 formulas Calc accepts compute as in Calc". Red on main: 9 FAILs (= SUM( A1 : A2 ), =SUM( 'My Sheet'!A1 : A2 ), =SUM(S2!A1:S2!A2), =SUM(1,2, =(1+2, =SUM(A1:A2, =SUM(A1 :A2), the two-'My Sheet' range, =IF(...,"other"). ./test.sh OK, 136 tests. Other check scripts green: tests/eval, recalc, e2e/engine, cli checks, a1_b1_refs, a1_b2_precedence.
> No regression on b2 (WI 2's check, run for information): 57 FAILs on main, 53 on the WI, and no new FAILs. The WI fixes =(1, =((1, =((1+2) and =SUM(A1:A2, as in Calc.
> 
> AC b1 against the diff:
> - src/parser/parse.py:166-169 close(): a missing ")" is accepted only at the end of the formula (primary :268, call args :286).
> - :171-186 range_end(): A1 : A2 with spaces, and a second end that names the same sheet (case-insensitive), rebased to the first end's sheet.
> - :31 _REF_END stops a reference before "!", so S2!A1:S2!A2 tokenizes as two references.
> - :47 ":" is an operator token.
> - Tests: tests/parser/test_parser.py:75-98 (spaces, both-ends sheet, the closing at end, and cases that stay malformed: =(1+, =SUM(1,, =(1 2). tests/eval/test_eval.py:118-123 moves "=SUM(1" from malformed to "computes 1", and adds =(1+2 -> 3.
> Scope: src/parser, tests/parser, tests/eval are all in path_scope.
> 
> Held-out fidelity probe (my own UNO run of LibreOffice 26.8, a copy of a_v1_pf_probe.py on a new port, 20 formulas next to the same data, vs ./engine on the WI). These match Calc: =(1 -> 1; =SUM(1,2 -> 3; =SUM (1,2) -> 3; =-(1 -> -1; =SUM(A1:A2,(3 -> 6; =SUM( A1 : A2 ) * 2 -> 6; =IF(A1=1,SUM(1,2 -> 3; =  1 + 2   -> 3; =SUM(A1:A2 ) -> 3; =SUM(A1 : B1) -> 1; =ABS(-(2 -> 2; =1+(2 -> 3; =SUM($A$1 : A2) -> 3; =(1)+(2 -> 3. These differ, none claimed by b1 and none made worse:
> (a) =A1:A2 and =A1 : A2 in C1 give 1, where Calc (via UNO) gives #VALUE!. =A1:A2 already gives 1 on main: the evaluator's implicit intersection, not this parser change. =s2!A1:S2!A2 gives 3 the same way.
> (b) Range chaining =SUM(A1:A2:A1): Calc 3, the engine #VALUE! (main too; the WI's test pins =A1:B2:C3 as a ParseError).
> (c) 3-D ranges across sheets (=SUM(S2!A1:Sheet1!A2), Calc 21): #VALUE! here, as on main. Possible follow-ups for the Gm, not this intent's bullets.
> 
> CONFLICT: a-i1's landed check tests/parser/checks/a1_b3_malformed.sh now fails on this WI: "FAIL '=(1' parsed as 1.0, want ParseError" and "FAIL '=SUM(1,2' parsed as (SUM 1.0 2.0), want ParseError". It passes on main. That check's list predates this intent. LibreOffice computes =(1 as 1 and =SUM(1,2 as 3 (the plan's a_v1_pf_calc.json, and my rerun above), and this intent's certified b1 requires it. So the new behaviour is right and a1_b3's two entries are stale. It is not in ./test.sh, so landing is not blocked. Whoever keeps product checks (Gm/human) should retire or replan those two a1_b3 entries, or a later rerun of a-i1's checks will report a false regression. -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-pf-b1` | b1 | `tests/parser/checks/a_v1_pf_b1_accept.sh` | red | — |

### `wi-a-v1-parse-fidelity-2`: Calc's codes for broken formulas and empty calls

Malformed formulas give Calc's Err:508/509/510/511/520 codes by its left-to-right rule and out-of-range numbers Err:502 instead of #VALUE!, and calls with no arguments give Err:511 (or Calc's empty value for SUM, COUNT, COUNTA, PRODUCT, AVERAGE, CONCATENATE) instead of 0 or a crash.

Status: landed (`60659f1ea40a`) · depends on `wi-a-v1-parse-fidelity-1`

**The passing review noted:** > PASS, attempt 3 (972c16d). Verify reran in a worktree of the WI with the plan's checks (4793976): ac-pf-b2 tests/parser/checks/a_v1_pf_b2_errors.sh ok on all 71 Calc cases (red on main a3ff015, 53 FAIL lines), and b1 is still ok. ./test.sh is OK with 141 tests. Earlier checks: only tests/parser/checks/a1_b3_malformed.sh is red, with output identical to main's. That is the CONFLICT carried from WI-1 (it wants '=(1' and '=SUM(1,2' to be ParseErrors; Calc computes them). It needs a human/Gm decision; this WI did not cause it.
> 
> Attempt-2 findings are fixed, checked against Calc 26.8.1.1 over UNO. =STDEV() and =STDEV( are #DIV/0! (src/eval/__init__.py _EMPTY_CALL_OK). The group-list family is now right: =(2, =(2; =(2,, =((2, =SUM((2, =SUM(1,(2, =1+(2, =IF((1, give Err:511, and =(2,3) =(2,) =(1,2 =SUM((2,3)) =SUM((1,2),3) give Err:509 (src/parser/parse.py primary(), the group branch, plus the deferred code). All of my earlier 129 held-out cases (all 40 functions called empty and half-open, the separator/%/')'/Err:502 corners) still match Calc, apart from the 5 below that were already wrong on main. I sent 51 new held-out cases at the new ':' handling and the deferred list code, and 36 match Calc: A1:(A2), A1:+A2, A1:+-A2 520, A1:1 / A1:TRUE / A1:"A2" / A1:(A2+1) / A1:(2,3) 502, A1:B #NAME?, (1,2)+1E400 502, IFERROR((1,2),0) 509, (2,3)+( 511, A1:2+ 520. A 60,000-formula random fuzz of evaluate() raised no Python exception. All 5 paths are in scope.
> 
> Left for WI-3 or the Gm (none of these is a malformed-formula case the bullets name, and none was right on main, so they are not grounds to fail the last attempt):
> - =SUM(A1:+ gives Err:520; Calc gives Err:511 (a sign then the end inside an open '('; main gave #VALUE!). This is the only malformed-code mismatch I found.
> - A range whose end is a function, =SUM(A1:INDEX(A1:A2,2)) and =SUM(A1:IF(1,A2,A1)), now gives Err:502; Calc computes 3 (main gave #VALUE!). A reference union in a group, =SUM((A1,A2)) or =SUM((A1;A2)), gives Err:509; Calc gives 3 (main #VALUE!). Both are reference forms the plan does not cover: worth a follow-up intent.
> - Implicit intersection is not done (already so on main): =A1:A2, =(A1:A2), =-A1:A2 and =SUM(-A1:A2) give 1 or -1 where Calc in C1 gives #VALUE!. Because of that, =A1:+A2 now gives 1 where main matched Calc's #VALUE!: that comes from the existing intersection gap, not from a wrong parse.
> - Already wrong on main, outside this plan: =SUM(1:2) (whole rows, out of scope), =SUM(A1:A2:A2) 3 in Calc, =SUM(A1:A2:) Err:511 in Calc, =SUM(A1:S2!A2) #NAME? in Calc; =COUNTIF(A1:A2) Err:504 (Calc Err:511), =INDEX(A1:A2) 1 (Calc #VALUE!), =TRUE()/=FALSE() #NAME? (Calc 1/0).
> Usefulness is not judged here (that is the judge check on WI-3); this review is about fidelity only.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-pf-b2` | b2 | `tests/parser/checks/a_v1_pf_b2_errors.sh` | red | — |

### `wi-a-v1-parse-fidelity-3`: Product tests for parse fidelity

Adds tests/parser/test_parse_fidelity.py, run by ./test.sh, covering the accepted forms, the parse error codes and empty calls, so the product keeps Calc's behaviour.

Status: landing (`1ca6a2287c7b`) · depends on `wi-a-v1-parse-fidelity-2`

**The passing review noted:** > PASS (166fa9d, attempt 1). Only test files, both in scope: tests/parser/test_parse_fidelity.py (+74) and tests/parser/parse_fidelity_calc.json (+1055). No product code changed.
> 
> Verify, rerun in a worktree of the WI with the plan's checks (4793976):
> - ac-pf-suite (tests/parser/checks/a_v1_pf_suite.sh): ok, "the product's parse-fidelity tests run and pass (5)". On main 140fa03 it is red ("no tests in tests/parser/test_parse_fidelity.py").
> - b1 and b2 still pass.
> - ./test.sh: OK, 146 tests (141 before), so ./test.sh's discovery picks the new tests up. None is skipped.
> - Earlier checks: only tests/parser/checks/a1_b3_malformed.sh is red, the same as on main. That is the CONFLICT carried since WI-1: it wants '=(1' and '=SUM(1,2' to be ParseErrors, but Calc computes them. It needs the Gm's or the human's decision.
> 
> Fidelity of the expected values: I reran LibreOffice Calc 26.8.1.1 headless over UNO (the plan's probe on another port) on all 259 formulas of parse_fidelity_calc.json, with its data. Result: 0 mismatches, and the data is identical. So the values come from Calc and none is hand-written.
> - The tests cover what the plan names: formulas Calc accepts (spaces, sheets on both ends of a range, a missing final ')'); Err:508/509/510/511/520 for malformed formulas; Err:502 for out-of-range numbers; and empty calls, STDEV included. Each formula is computed alone through src.cli.compute, the same path as ./engine. Numbers are compared within 1e-9, and errors and text exactly.
> - test_parse_fidelity.py:46 subTest reports each formula on its own.
> 
> Not covered, as follow-ups for the Gm. These are the gaps I found reviewing WI-2; the file leaves them out, which is consistent with pinning only what was fixed, but its "source" line names only =IF((1 as excluded:
> - =SUM(A1:+ gives Err:520 (Calc Err:511).
> - =SUM(A1:INDEX(A1:A2,2)) and =SUM(A1:IF(1,A2,A1)) give Err:502 (Calc 3).
> - =SUM((A1,A2)) gives Err:509 (Calc 3).
> - No implicit intersection: =A1:A2 and =A1:+A2 in C1 give 1 (Calc #VALUE!).
> - =SUM(1:2), =COUNTIF(A1:A2), =INDEX(A1:A2), =TRUE()/=FALSE().
> The judge check ac-pf-judge (usefulness) is for a signer, not this review.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-pf-suite` | b1, b2 | `tests/parser/checks/a_v1_pf_suite.sh` | red | — |
| `ac-pf-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through ./engine as shipped, can an ordinary user type formulas the way people do (spaces around operators and ranges, a forgotten closing parenthesis, sheet names on both ends of a range) and get results, and when a formula is really broken, get a specific error rather than a generic #VALUE! or a crash? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | formulas with spaces around tokens, ranges with a sheet on both ends, and a missing final parenthesis compute as LibreOffice computes them | `tests/parser/checks/a_v1_pf_b1_accept.sh` — |
| not yet | b2 | malformed formulas, =1E400 and empty-argument calls give LibreOffice's error codes, with expected values from running LibreOffice | `tests/parser/checks/a_v1_pf_b2_errors.sh` — |

## 5. Out of scope and risks

- **Out of scope:** array literals and whole-column references
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/parser/**`, `exp-a:src/eval/**`, `exp-a:src/recalc/**`, `exp-a:tests/parser/**`, `exp-a:tests/eval/**`, `exp-a:tests/recalc/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-parse-fidelity-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-parse-fidelity-1` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-v1-parse-fidelity-2` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-v1-parse-fidelity-2` | `rev-a@alebairos` (passed attempt 3) |
| Implemented `wi-a-v1-parse-fidelity-3` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-parse-fidelity-3` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-v1-parse-fidelity-1`:

- `tests/parser/checks/a_v1_pf_probe.py` +56 −0 (plan check)
- `src/parser/parse.py` +30 −6
- `tests/parser/checks/a_v1_pf_common.py` +31 −0 (plan check)
- `tests/parser/checks/a_v1_pf_suite.sh` +27 −0 (plan check)
- `tests/parser/test_parser.py` +26 −1 (test)
- `tests/parser/checks/a_v1_pf_b2_errors.sh` +14 −0 (plan check)
- `tests/parser/checks/a_v1_pf_b1_accept.sh` +10 −0 (plan check)
- `tests/eval/test_eval.py` +5 −1 (test)
- `tests/parser/checks/a_v1_pf_calc.json` +1 −0 (plan check)

Files landed by `wi-a-v1-parse-fidelity-2`:

- `src/parser/parse.py` +106 −21
- `tests/eval/test_eval.py` +48 −3 (test)
- `src/eval/__init__.py` +31 −4
- `tests/recalc/test_recalc.py` +3 −2 (test)
- `src/recalc/__init__.py` +2 −2

Landing pull request: [exp-a #36](https://github.com/alebairos/sheet-exp-a/pull/36)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 6 h 54 min so far
- Loops: 5 (D1 spec 1, D2 plan 2, D5 review 2)
- Waste: 32 min
- Size: 202 lines (+169 −33, 8 files, ≤400; tests 89 lines); plan check files laid over by land, not in the size: +139 −0, 6 files
