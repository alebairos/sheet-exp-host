# Intent `a-i6-logic-text`

## 1. Outcome

> The 9 logic and information functions and the 8 text functions of SPEC.md compute as in Calc

Kind: Feature · State: planned · 2 work items · 2 bullets

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

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a6-b1` | b1 | `tests/functions/logic_text/checks/a6_b1_logic.sh` | red | — |

### `wi-a-i6-logic-text-2`: Text functions

Add src/functions/logic_text/text.py with CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER and TRIM, coercing numbers, booleans and blanks to text as Calc does and returning Calc's errors, so text formulas match Calc.

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a6-b2` | b2 | `tests/functions/logic_text/checks/a6_b2_text.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT, ISERROR match Calc | no landed check |
| not yet | b2 | CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM match Calc, coercion and errors included | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/functions/logic_text/**`, `exp-a:tests/functions/logic_text/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | — |
| Implemented `wi-a-i6-logic-text-1` | — |
| Reviewed `wi-a-i6-logic-text-1` | — |
| Implemented `wi-a-i6-logic-text-2` | — |
| Reviewed `wi-a-i6-logic-text-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 21 h 08 min so far
- Loops: 3 (D1 spec 1, D2 plan 2)
- Waste: 8 min
- Size: nothing landed yet
