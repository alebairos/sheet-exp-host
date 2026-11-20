# Intent `a-i6-logic-text`

## 1. Outcome

> The 9 logic and information functions and the 8 text functions of SPEC.md compute as in Calc

Kind: Feature · State: awaiting the verdict · 2 work items · 2 bullets

## 2. What you will see

The 9 logic and information functions and the 8 text functions work in formulas exactly as Calc computes them: =IF(A1>0,"yes","no"), =IFERROR(A2/B2,0), =AND(...), =ISBLANK(A5), =LEFT(A1,3), =TRIM("  a  b ") give Calc's results, TRUE/FALSE as booleans, and Calc's errors. Calc's habits included: a TRUE cell counts as a number (ISNUMBER is TRUE, CONCATENATE writes "1"), AND/OR ignore text in ranges, IF can hand back a cell reference (ISBLANK(IF(1,A5)) is TRUE), TRIM collapses inner spaces, and a negative length is Calc's Err:502. The media is Calc's answer sheet: the 205 formulas the checks run, each with what LibreOffice returned.

- [a-i6-logic-text/README.md](https://github.com/alebairos/sheet-exp-host/blob/00204cfcf2c5c0ed69c2ab72aa6ffc4df99e7010/a-i6-logic-text/README.md)
- [a-i6-logic-text/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/00204cfcf2c5c0ed69c2ab72aa6ffc4df99e7010/a-i6-logic-text/calc-answers.md)
- [a-i6-logic-text/lt.out.json](https://github.com/alebairos/sheet-exp-host/blob/00204cfcf2c5c0ed69c2ab72aa6ffc4df99e7010/a-i6-logic-text/lt.out.json)
- [a-i6-logic-text/lt.py](https://github.com/alebairos/sheet-exp-host/blob/00204cfcf2c5c0ed69c2ab72aa6ffc4df99e7010/a-i6-logic-text/lt.py)
- [a-i6-logic-text/probe.py](https://github.com/alebairos/sheet-exp-host/blob/00204cfcf2c5c0ed69c2ab72aa6ffc4df99e7010/a-i6-logic-text/probe.py)
- [a-i6-logic-text/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/00204cfcf2c5c0ed69c2ab72aa6ffc4df99e7010/a-i6-logic-text/gencheck.py)

## 3. Approach

Two modules under src/functions/logic_text, one per work item, registering with @register (a-i0's registry finds them, no shared file edited) and following a-i3's calling convention (a reference arrives as a src.eval.Range, any other argument as a Value with errors left in; a function may return a Range). Logic first, since formulas branch on it: IF(cond, then, else) and NOT take their argument through a local to-boolean (numbers and booleans: non-zero is TRUE; text that reads as a number converts first, so IF("3" cell) is TRUE and NOT("1") FALSE; the text TRUE/FALSE in any case is that boolean; blank is FALSE; any other text #VALUE!; errors through) and returns the chosen argument untouched, a Range included, a missing else FALSE; IFERROR returns its first argument unless it is an error; AND/OR walk ranges taking numbers and booleans, skipping text and blanks; a typed argument must be a number or boolean (typed text, even "TRUE", is #VALUE!, as Calc gives for AND("TRUE")); #VALUE! when nothing logical was seen, the first error through; ISBLANK true only for a reference to an empty cell; ISNUMBER (a boolean counts, as Calc stores it as a number), ISTEXT, ISERROR on the referenced cell's value. Text second: one local to-text (src.values.to_text, plus booleans as 1/0 the way a-i3's & does) and a to-count (to_number, truncated, negative is Err:502); CONCATENATE (missing arguments are empty), LEFT/RIGHT (count defaults to 1), MID (start below 1 Err:502, missing length Err:511), LEN, UPPER/LOWER (Python's Unicode case mapping, with ß upper-casing to ẞ as Calc does), TRIM (strip and collapse runs of spaces). Each work item adds unit tests in tests/functions/logic_text. No other function is used by the checks: the boolean constants are written TRUE and FALSE (the parser's literals), not the TRUE()/FALSE() functions, which are outside SPEC's 40.

- **Reuses:** src.functions.register and registry() (a-i0); src.eval's Range and calling convention (a-i3), including returning a Range; src.values Values, to_number, to_text and format_number (a-i2).
- **Removes:** none
- **Rejected:** Excel's rules (ISNUMBER(TRUE cell) FALSE, booleans skipped by AND in ranges as Excel does for text only): the suite is computed by LibreOffice. A separate text formatter in this intent for very large/small numbers: number-to-text belongs to src/values (a-i2), which differs from Calc there (1E+20 vs Calc's 1E+020, 1E-07 vs 0.0000001; see the media); those cases are left out of the checks and are worth a Defect on src/values, so & and CONCATENATE stay consistent. Mapping Err:502/Err:511 to #VALUE! (LibreOffice's xlsx export): kept as Calc displays them, as a-i4 and a-i5 do; one constant per module if the human rules otherwise.

## 4. Work items

### `wi-a-i6-logic-text-1`: Logic and information functions

Add src/functions/logic_text/logic.py with IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT and ISERROR as Calc computes them (booleans, references and errors included), so formulas can branch and test cells.

Status: landed (`e68ed241fd38`)

**The passing review noted:** > PASS. Reran verify on f45e7d0 (worktree): a6_b1_if.sh "38 cases match Calc", a6_b1_and_or_not.sh "38 cases match Calc", a6_b1_is.sh "37 cases match Calc"; on the plan commit 90fa643 all three fail (38/38, 38/38, 37/37 differ). ./test.sh OK.
> - ac-a6-b1-if (b1): src/functions/logic_text/logic.py:47 _condition (bool/number non-zero, blank FALSE, numeric text and TRUE/FALSE text in any case, other text #VALUE!, errors through); IF (logic.py:68) returns the chosen argument untouched (a Range stays a reference), missing else FALSE; IFERROR (logic.py:81) with Err:518 for an omitted value.
> - ac-a6-b1-and-or-not (b1): _logicals (logic.py:92) skips text/blank in references, typed text #VALUE!, nothing logical #VALUE!, first error through; NOT (logic.py:130) with Err:508 for too many arguments.
> - ac-a6-b1-is (b1): ISBLANK only for a reference to an empty cell (logic.py:145); ISNUMBER counts booleans; ISTEXT/ISERROR on the collapsed value.
> - Cross-checked 21 more formulas on my own fixture against LibreOffice 26.8.1.1 headless, all equal: NOT(""), IF("",1,2), IF(<cell with "">,1,2) #VALUE!; IF(" true ") 1; NOT("1e1") FALSE; ISNUMBER(TRUE) TRUE; ISTEXT/ISBLANK of a "" cell TRUE/FALSE; ISBLANK of a formula reading an empty cell FALSE; AND over blank/""/"x" #VALUE!; OR over "x",0,TRUE TRUE; AND("1") #VALUE!; IF(1,) and IF(0,1,) 0; NOT(1E-320) FALSE; IF(" 1 ") 1; AND(TRUE,1,0) FALSE; OR(#DIV/0!,TRUE) #DIV/0!; ISBLANK("") FALSE.
> Scope: logic.py, tests/functions/logic_text/__init__.py, test_logic.py, all inside the scope; no check edited.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a6-b1-if` | b1 | `tests/functions/logic_text/checks/a6_b1_if.sh` | red | — |
| `ac-a6-b1-and-or-not` | b1 | `tests/functions/logic_text/checks/a6_b1_and_or_not.sh` | red | — |
| `ac-a6-b1-is` | b1 | `tests/functions/logic_text/checks/a6_b1_is.sh` | red | — |

### `wi-a-i6-logic-text-2`: Text functions

Add src/functions/logic_text/text.py with CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER and TRIM, coercing numbers, booleans and blanks to text as Calc does and returning Calc's errors, so text formulas match Calc.

Status: landed (`3fbaf7a6a2d2`)

**The passing review noted:** > PASS. Reran verify on 08debe5 (worktree): a6_b2_concat_len.sh "32 cases match Calc", a6_b2_left_right_mid.sh "37", a6_b2_case_trim.sh "23"; on the plan commit 90fa643 all three fail (32/32, 37/37, 23/23 differ). ./test.sh OK.
> - ac-a6-b2-concat-len, -left-right-mid, -case-trim (b2): src/functions/logic_text/text.py:31 _text (booleans as 1/0, then src.values.to_text, errors through), :39 _count (truncated, negative or non-finite Err:502), CONCATENATE :52, LEFT/RIGHT :63-82 (count defaults to 1), MID :85 (start < 1 Err:502, too few args Err:511), LEN/UPPER (ß->ẞ)/LOWER/TRIM (spaces only) :114-131.
> - Cross-checked 22 more formulas against LibreOffice 26.8.1.1 headless; equal: LEN/LEFT/MID/RIGHT/UPPER over "a😀b" (Calc counts code points, as Python does), CONCATENATE(TRUE,1) "11", a TRUE cell "1x", LEN(1/3) 17, UPPER("Straße") STRAẞE, LOWER("ΟΔΟΣ") "οδος" (final sigma), UPPER("ﬀ") "FF", TRIM keeps tabs, MID("abc",1,) and LEFT("abc",) "", LEFT(..,2.9) "ab", MID(..,0.5,1) Err:502, MID(..,5,1) "", RIGHT(..,-1) Err:502, LEN("") 0.
> Not this WI (outside its scope), for the Gm as a Defect on src/values: number-to-text differs from Calc for large/small magnitudes. src/values/__init__.py:192 format_number writes 1E+21 where Calc writes 1E+021 (three-digit exponent), and 1E-07 where Calc writes 0.0000001. Visible through every text conversion: CONCATENATE(1E21) "1E+021" vs "1E+21"; ="x"&1E-7 "x0.0000001" vs "x1E-07"; LEN(123456789012345678) 21 vs 20; LEN(1E-20) 6 vs 5 (all LibreOffice 26.8.1.1 vs engine). -1.5E100 agrees.
> Scope: text.py, tests/functions/logic_text/__init__.py, test_text.py, all inside the scope; no check edited.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a6-b2-concat-len` | b2 | `tests/functions/logic_text/checks/a6_b2_concat_len.sh` | red | — |
| `ac-a6-b2-left-right-mid` | b2 | `tests/functions/logic_text/checks/a6_b2_left_right_mid.sh` | red | — |
| `ac-a6-b2-case-trim` | b2 | `tests/functions/logic_text/checks/a6_b2_case_trim.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT, ISERROR match Calc | `tests/functions/logic_text/checks/a6_b1_if.sh` —, `tests/functions/logic_text/checks/a6_b1_and_or_not.sh` —, `tests/functions/logic_text/checks/a6_b1_is.sh` — |
| not yet | b2 | CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM match Calc, coercion and errors included | `tests/functions/logic_text/checks/a6_b2_concat_len.sh` —, `tests/functions/logic_text/checks/a6_b2_left_right_mid.sh` —, `tests/functions/logic_text/checks/a6_b2_case_trim.sh` — |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/functions/logic_text/**`, `exp-a:tests/functions/logic_text/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i6-logic-text-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-i6-logic-text-1` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-i6-logic-text-2` | `impl-a1@alebairos` |
| Reviewed `wi-a-i6-logic-text-2` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-i6-logic-text-1`:

- `src/functions/logic_text/logic.py` +172 −0
- `tests/functions/logic_text/checks/a6_b1_and_or_not.sh` +77 −0 (plan check)
- `tests/functions/logic_text/checks/a6_b1_if.sh` +77 −0 (plan check)
- `tests/functions/logic_text/checks/a6_b1_is.sh` +76 −0 (plan check)
- `tests/functions/logic_text/checks/a6_b2_left_right_mid.sh` +76 −0 (plan check)
- `tests/functions/logic_text/checks/a6_b2_concat_len.sh` +71 −0 (plan check)
- `tests/functions/logic_text/test_logic.py` +69 −0 (test)
- `tests/functions/logic_text/checks/a6_b2_case_trim.sh` +62 −0 (plan check)
- `tests/functions/logic_text/__init__.py` +0 −0 (test)

Files landed by `wi-a-i6-logic-text-2`:

- `src/functions/logic_text/text.py` +131 −0
- `tests/functions/logic_text/test_text.py` +76 −0 (test)

Landing pull request: [exp-a #16](https://github.com/alebairos/sheet-exp-a/pull/16)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 22 h 06 min so far
- Loops: 4 (D1 spec 1, D2 plan 3)
- Waste: 13 min
- Size: 303 lines (+303 −0, 5 files, ≤400; tests 145 lines); plan check files laid over by land, not in the size: +439 −0, 6 files
