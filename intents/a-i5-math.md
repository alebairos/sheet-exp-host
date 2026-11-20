# Intent `a-i5-math`

## 1. Outcome

> The 20 math and statistics functions of SPEC.md compute as in Calc, including ranges, blanks, text in ranges, and ROUND's half-away-from-zero

Kind: Feature · State: in work · 3 work items · 3 bullets

## 2. What you will see

The 20 math and statistics functions work in formulas exactly as Calc computes them: =SUM(A1:A8), =AVERAGEIF(E1:E8,"apple",F1:F8), =ROUND(2.5,0) and so on give Calc's numbers and Calc's errors. That includes Calc's habits: text and blanks in a range are skipped but a TRUE cell counts as 1; ROUND rounds half away from zero on the decimal value you see (ROUND(1.005,2) is 1.01, ROUNDUP(0.1+0.2,1) is 0.3); criteria understand >, <=, <>, wildcards (a*, b?nana) and match text case-insensitively; an error in a range comes through. The media is Calc's answer sheet: the 230 formulas the checks run, each with what LibreOffice itself returned.

- [a-i5-math/README.md](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/README.md)
- [a-i5-math/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/calc-answers.md)
- [a-i5-math/math.out.json](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/math.out.json)
- [a-i5-math/math.py](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/math.py)
- [a-i5-math/probe.py](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/probe.py)
- [a-i5-math/xlsx_probe.py](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/xlsx_probe.py)
- [a-i5-math/errs.csv](https://github.com/alebairos/sheet-exp-host/blob/bfaba19b527798570488615f2396daa5560abc1a/a-i5-math/errs.csv)

## 3. Approach

Three modules under src/functions/math, one per work item, each registering its functions with @register (a-i0's registry finds them; no shared file edited), all following a-i3's calling convention (a reference arrives as a src.eval.Range, any other argument as a Value). Aggregates first, the most used: one local helper walks the arguments the way Calc does: from a Range, numbers and booleans (as 1/0) are taken, text and blanks skipped, the first error returned; a typed argument is coerced (a boolean is 1/0; for COUNT numeric text counts; for SUM/AVERAGE/PRODUCT text is #VALUE!, for MIN/MAX/MEDIAN/STDEV it is Err:504, as Calc does). SUM, PRODUCT, COUNT, COUNTA, AVERAGE (#DIV/0! when empty), MIN/MAX (0 when empty), MEDIAN (#VALUE! when empty), STDEV (sample, #DIV/0! under two values). Rounding second: ROUND/ROUNDUP/ROUNDDOWN round the number first to 15 significant digits (what Calc shows) and then by decimal digits away from or toward zero (count truncated, negative counts allowed); INT floors; MOD is a - b*floor(a/b) with the divisor's sign, #DIV/0! for 0; ABS; POWER as the evaluator's ^ (#NUM! for 0^-1, odd roots of negatives, overflow); SQRT of a negative is Err:502 as Calc says. Criteria third: one parser turns a criterion into a test (= <> < > <= >= prefixes; a number or numeric text compares numerically against numbers and as text against text; text matches case-insensitively with * ? and ~ escapes, anchored to the whole cell; "" and "=" match blanks, "<>" non-blanks), then SUMIF/COUNTIF/AVERAGEIF; a sum range is resized from its top-left cell to the criteria range's shape, as Calc does. Each work item adds unit tests next to its check in tests/functions/math.

- **Reuses:** src.functions.register and registry() (a-i0); src.eval's Range and calling convention (a-i3), whose values() already gives blanks and errors; src.values Values, to_number/to_text coercions and compare (a-i2).
- **Removes:** none
- **Rejected:** Python's round() and math.ceil on the binary value: ROUND(1.005,2) would be 1.0 and ROUNDUP(0.1+0.2,1) 0.4, unlike Calc. The decimal module for everything: slower and still needs Calc's 15-digit step. Excel's rules (booleans in ranges ignored, SQRT(-1) is #NUM!): the suite is computed by LibreOffice, and Calc stores TRUE as 1. Mapping Calc's Err:502/Err:504 to #VALUE! (what LibreOffice's xlsx export writes): kept as Calc displays them, consistent with a-i4-recalc's Err:522; if the human prefers the xlsx names, it is a one-line change in each module and the checks' expected values. Regular-expression criteria: a document option, off by default.

## 4. Work items

### `wi-a-i5-math-1`: Aggregates: SUM to STDEV

Add src/functions/math/aggregate.py with SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN and STDEV, walking ranges and arguments as Calc does (text and blanks skipped, TRUE as 1, errors through), so the commonest formulas compute.

Status: landed (`23ac95711c5e`)

**The passing review noted:** > PASS. Reran verify on the WI commit 288aa37 (worktree): tests/functions/math/checks/a5_b1_aggregates.sh gives "ok b1: 84 cases match Calc"; on the plan commit bac39e3 it fails with 84 of 84 differing (functions unregistered, #NAME?). ./test.sh OK.
> - ac-a5-b1 (b1): src/functions/math/aggregates.py _groups (line 34) takes numbers and booleans from a Range, skips text and blanks, returns the first error, and makes typed text #VALUE! for SUM/AVERAGE/PRODUCT and Err:504 for MIN/MAX/MEDIAN/STDEV, which is what the 84 Calc-pinned cases (ranges with blanks, text, booleans and errors) exercise. _calc_sum reproduces Calc's Neumaier+approxAdd so SUM(0.1,0.2) and near-cancelling sums match. COUNT/COUNTA are separate walks (Range.values) so errors are skipped by COUNT and counted by COUNTA.
> - Probed beyond the check: SUM/PRODUCT/AVERAGE of 1e308+1e308 give #NUM!; COUNTA over an error, an empty-string cell and a blank gives 2; COUNT(1,) gives 2 (omitted arg counts, as Calc); MEDIAN of 1..4 is 2.5; STDEV of 1..4 is 1.2909944487358056.
> Scope: src/functions/math/aggregates.py, tests/functions/math/__init__.py, tests/functions/math/test_aggregates.py, all inside the intent's scope; no check edited.
> Note, not blocking: all three WIs of this intent add tests/functions/math/__init__.py; it is an empty file in each, so the landings should merge cleanly, but whoever lands second sees it already present.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a5-b1` | b1 | `tests/functions/math/checks/a5_b1_aggregates.sh` | red | — |

### `wi-a-i5-math-2`: Rounding and arithmetic functions

Add src/functions/math/rounding.py with ROUND, ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER and SQRT, rounding on the decimal value Calc shows and returning Calc's errors, so numeric formulas match Calc to the last digit.

Status: landed (`a8ff6a245f5e`)

**The passing review noted:** > PASS (attempt 2). Reran verify on e250e4b (worktree): a5_b2_rounding.sh "ok b2: 87 cases match Calc"; base red as in attempt 1; ./test.sh OK.
> - The attempt-1 defect is fixed: src/functions/math/rounding.py mod() now returns #VALUE! when a / b or floor(a/b)*b is not finite, and _approx_floor passes non-finite input through instead of raising; _round keeps x when rounding overflows. No exception escapes any more.
> - Checked against LibreOffice 26.8.1.1 headless: MOD(1E308,1E-10), MOD(-1E308,1E-10), MOD(1E300,1E-10), MOD(5,1E-320) are #VALUE! in both; ROUNDUP(1.7E308,-308) and ROUND(1.7E308,-308) 1.7E+308 in both; INT(1E308) 1E+308; MOD(1E20,3) 0; MOD(-7,2.5) 0.5; MOD(1E-300,1E300) 1E-300: all agree. Unit tests for these added in tests/functions/math/test_rounding.py.
> - ac-a5-b2 evidence from attempt 1 still holds (rounding on the 15-digit shown value, MOD with the divisor's sign, SQRT of a negative Err:502, POWER via the ^ operator).
> Scope: rounding.py and test_rounding.py only, inside the scope; no check edited. Nit from attempt 1 (private src.eval._power import) unchanged and still not blocking.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a5-b2` | b2 | `tests/functions/math/checks/a5_b2_rounding.sh` | red | — |

### `wi-a-i5-math-3`: Criteria: SUMIF, COUNTIF, AVERAGEIF

Add src/functions/math/criteria.py with Calc's criteria matching (comparison prefixes, wildcards, case-insensitive text, blanks) and SUMIF, COUNTIF, AVERAGEIF on top of it, so conditional totals match Calc.

Status: landing (`ab6081615a13`)

**The passing review noted:** > PASS (attempt 2). Reran verify on b1f5ec4 (worktree): a5_b3_criteria.sh "ok b3: 59 cases match Calc"; base red as in attempt 1; ./test.sh OK.
> - The attempt-1 defect is fixed: src/functions/math/criteria.py now adds SUMIF/AVERAGEIF matches with _calc_sum (Calc's KahanSum: Neumaier with the last term held back and cancelled to 0 when approxEqual to minus the rest), in the criteria range's walk order, instead of math.fsum.
> - Checked against LibreOffice 26.8.1.1 headless, bit for bit (LO side via ORG.LIBREOFFICE.RAWSUBTRACT(x,c)*1E20, since Calc's own minus is approximate): SUMIF over 0.1,0.7,-0.8,"t",0.3 with "<>t" is 0.3-5.551115123125783E-17 in both; AVERAGEIF over 0.1,0.2,-0.3,1E-17,0.7,0.1 with ">0" is 0.22+2.7755575615628914E-17 in both; SUMIF of 0.1,0.2,-0.3,1E-17,0.7,0.1 is exactly 0.8 in both. Also equal: 0.1,0.2,-0.3 -> 0; 0.3,-0.1,-0.2 -> 0; 1.1,2.2,3.3,-6.6 -> 0 (and AVERAGEIF 0); 1E16,1,-1E16,1 -> 2; 1E308,1E308,-1E308 -> #NUM!; a 2-D range A1:B4 -> 2.
> - ac-a5-b3 evidence from attempt 1 still holds (criterion parsing, wildcards, blanks, sum-range resize).
> Scope: criteria.py and test_criteria.py only, inside the scope; no check edited.
> For the Gm, not this WI: wi-a-i5-math-1's SUM (already passed) differs from Calc in the last bits on a plain range: SUM(F1:F5) with 0.1,0.7,-0.8,"t",0.3 is 0.3-5.55E-17 in the engine but 0.3-1.11E-16 in LibreOffice (Calc likely adds number runs of a range with its vectorised array sum, a different order). Invisible at 15 significant digits; matters only if a suite compares raw doubles. Also the intent now has two Calc-sum helpers (aggregates._calc_sum, criteria._calc_sum) that could be one.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a5-b3` | b3 | `tests/functions/math/checks/a5_b3_criteria.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN, STDEV match Calc on ranges with blanks and text | `tests/functions/math/checks/a5_b1_aggregates.sh` — |
| not yet | b2 | ROUND, ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER, SQRT match Calc, errors included | `tests/functions/math/checks/a5_b2_rounding.sh` — |
| not yet | b3 | SUMIF, COUNTIF, AVERAGEIF match Calc's criteria | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/functions/math/**`, `exp-a:tests/functions/math/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i5-math-1` | `impl-a1@alebairos` |
| Reviewed `wi-a-i5-math-1` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-i5-math-2` | `impl-a2@alebairos` |
| Reviewed `wi-a-i5-math-2` | `rev-a@alebairos` (passed attempt 2) |
| Implemented `wi-a-i5-math-3` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-i5-math-3` | `rev-a@alebairos` (passed attempt 2) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-i5-math-1`:

- `src/functions/math/aggregates.py` +205 −0
- `tests/functions/math/checks/a5_b2_rounding.sh` +134 −0 (plan check)
- `tests/functions/math/checks/a5_b1_aggregates.sh` +131 −0 (plan check)
- `tests/functions/math/checks/a5_b3_criteria.sh` +107 −0 (plan check)
- `tests/functions/math/test_aggregates.py` +72 −0 (test)
- `tests/functions/math/__init__.py` +0 −0 (test)

Files landed by `wi-a-i5-math-2`:

- `src/functions/math/rounding.py` +151 −0
- `tests/functions/math/test_rounding.py` +78 −0 (test)

Landing pull request: [exp-a #17](https://github.com/alebairos/sheet-exp-a/pull/17)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 22 h 27 min so far
- Loops: 2 (D5 review 2)
- Waste: 11 min
- Size: 356 lines (+356 −0, 5 files, ≤400; tests 150 lines); plan check files laid over by land, not in the size: +372 −0, 3 files
