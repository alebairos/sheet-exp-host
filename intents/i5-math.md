# Intent `i5-math`

## 1. Outcome

> The 20 math and statistics functions of SPEC.md compute as in Calc, including ranges, blanks, text in ranges, and ROUND's half-away-from-zero

Kind: Feature · State: awaiting the verdict · 3 work items · 3 bullets

## 2. What you will see

The twenty math and statistics functions from SPEC.md answer as Calc does. =SUM(A1:A8) skips blanks and text and still adds TRUE as 1; =AVERAGE of an all-text range is #DIV/0!; =ROUND(1.5,0) is 2 and =ROUND(-1.5,0) is -2 (half away from zero); =MOD(-10,3) is 2; =SQRT(-1) is #NUM!; =SUMIF(F1:F8,">4") and =COUNTIF(E1:E8,"apple") follow Calc's criteria, including case-insensitive text and * wildcards. Errors in a summed range surface as that error.

- No media: Library functions with no screen; expected values live in tests/functions/math/checks/b*.sh

## 3. Approach

Implement the twenty callables in src/functions/math as a FUNCTIONS dict (uppercase name → callable) so i0's discover_functions and i3's registry() pick them up with no shared hand-edited table. Each callable takes the i3 calling convention: a Range for a reference or range argument (values() row by row, blanks included), otherwise a Value with errors left in, and returns a Value. Split the work by bullet: aggregates that walk ranges (SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN, STDEV), scalar/rounding ops (ROUND half-away-from-zero, ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER, SQRT), then criteria ops (SUMIF, COUNTIF, AVERAGEIF). Share a small private helper for "numbers in a range, skipping blanks and text" inside the package. Plan checks under tests/functions/math/checks call evaluate on constant-cell books. POWER(0,-1) returns #DIV/0! so it matches src.eval's ^ (certify reject); COUNTIF text criteria "10" and "3" were checked on LibreOffice Calc 26.8 (2 and 1).

- **Reuses:** src.eval.evaluate / Range / registry discovery (i3); src.values Number, Error, to_number, to_json (i2); i0 package layout with FUNCTIONS on src.functions.math.
- **Removes:** none
- **Rejected:** Registering each function through src.eval.register in the checks only: production discovery must stay on the package FUNCTIONS dict. Implementing criteria as Python eval of the criteria string: unsafe and not Calc. Putting helpers in src/eval: out of this intent's directories. One giant WI for all twenty: over the size budget and blocks parallel review of independent groups. Expecting #NUM! from POWER(0,-1): disagrees with the landed evaluator's 0^-1.

## 4. Work items

### `wi-i5-math-1`: Range aggregates

Add SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN and sample STDEV on ranges with blanks and text.

Status: landed (`93850d3313ee`)

**The passing review noted:** > pass review of wi-i5-math-1 @ 3dbc492 (attempt 1). Covers ac-b1 only.
> 
> verify: tests/functions/math/checks/b1_aggregates.sh EXIT 0 (ok b1).
> 
> ac-b1 / b1 (SUM AVERAGE MIN MAX COUNT COUNTA PRODUCT MEDIAN STDEV on ranges with blanks/text): check green via src.eval.evaluate. Diff only src/functions/math/__init__.py. _numbers skips Blank/Text, coerces Bool to 0/1, surfaces first error (:28-45). FUNCTIONS table registers all nine aggregates (:118-128). COUNTA counts non-blanks (:109-115). STDEV sample n-1 with DIV0 for n<2 (:101-106). Empty AVERAGE/STDEV → DIV0; empty MEDIAN → VALUE; empty SUM/MIN/MAX/COUNT/PRODUCT → 0 (:118-127). In path_scope; outside_scope null; no check-file edits in last_diff.
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/functions/math/checks/b1_aggregates.sh` | red | pass |

### `wi-i5-math-2`: Rounding and scalars

Add ROUND (half away from zero), ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER and SQRT with Calc errors.

Status: landed (`2d91c4ead6e9`)

**The passing review noted:** > pass review of wi-i5-math-2 @ 5fa81d3 (attempt 2). Covers ac-b2 only.
> 
> verify: tests/functions/math/checks/b2_scalars.sh EXIT 0 (ok b2), run against WI tip.
> 
> ac-b2 / b2 (ROUND ROUNDUP ROUNDDOWN INT MOD ABS POWER SQRT, errors included): check green. Scalars added on top of landed aggregates in src/functions/math/__init__.py via to_number and Decimal quantize; ROUND uses ROUND_HALF_UP (half away from zero) at :166-173. MOD uses Calc n-d*INT(n/d) with DIV0 on d=0 (:203-215). POWER(0,-1) returns DIV0 (:224-240) matching certify reject / eval ^. SQRT/POWER surface NUM on domain/overflow. FUNCTIONS maps aggregates plus the eight scalar names (:246-268).
> 
> land-retry: attempt 1 was scalars-only on pre-math-1 tip (merge conflict with landed aggregates). Attempt 2 rebases onto main and keeps aggregates while appending scalars — addresses the land failure; last_diff is additive on the shared file.
> 
> scope: last_diff src/functions/math/__init__.py in path_scope. No outside-scope paths. Criteria ops still absent (wi-i5-math-3).
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b2` | b2 | `tests/functions/math/checks/b2_scalars.sh` | red | pass |

### `wi-i5-math-3`: Conditional aggregates

Add SUMIF, COUNTIF and AVERAGEIF matching Calc criteria (comparisons, text, wildcards).

Status: landed (`23e1ea1cf65d`)

**The passing review noted:** > pass review of wi-i5-math-3 @ f7cdd90 (attempt 3). Covers ac-b3 only.
> 
> verify: tests/functions/math/checks/b3_conditional.sh EXIT 0 (ok b3). Spot-check b1_aggregates.sh and b2_scalars.sh EXIT 0 on tip after rebuild onto landed scalars.
> 
> ac-b3 / b3 (SUMIF COUNTIF AVERAGEIF match Calc's criteria): check green. Criteria helpers and the three callables appended on the landed aggregates+scalars FUNCTIONS table in src/functions/math/__init__.py. Registry exposes all twenty math names plus criteria.
> 
> land-retry: attempt 2 still conflicted with scalars land; attempt 3 rebuilds on main keeping aggregates+scalars while adding criteria — addresses the land failure. last_diff is additive on the shared file.
> 
> scope: last_diff src/functions/math/__init__.py in path_scope. No outside-scope paths.
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b3` | b3 | `tests/functions/math/checks/b3_conditional.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN, STDEV match Calc on ranges with blanks and text | `tests/functions/math/checks/b1_aggregates.sh` pass |
| PASS | b2 | ROUND, ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER, SQRT match Calc, errors included | `tests/functions/math/checks/b2_scalars.sh` pass |
| PASS | b3 | SUMIF, COUNTIF, AVERAGEIF match Calc's criteria | `tests/functions/math/checks/b3_conditional.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/functions/math/**`, `exp-b:tests/functions/math/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i5-math-1` | `impl-2@alebairos` |
| Reviewed `wi-i5-math-1` | `rev-1@alebairos` (passed attempt 1) |
| Implemented `wi-i5-math-2` | `impl-1@alebairos` |
| Reviewed `wi-i5-math-2` | `rev-1@alebairos` (passed attempt 2) |
| Implemented `wi-i5-math-3` | `impl-1@alebairos`, `impl-2@alebairos` |
| Reviewed `wi-i5-math-3` | `rev-1@alebairos` (passed attempt 3) |

Product checks:

- `tests/functions/math/checks/b1_aggregates.sh`: pass
- `tests/functions/math/checks/b2_scalars.sh`: pass
- `tests/functions/math/checks/b3_conditional.sh`: pass

Outcome report: none yet.

Files landed by `wi-i5-math-1`:

- `src/functions/math/__init__.py` +128 −0
- `tests/functions/math/checks/b2_scalars.sh` +103 −0 (plan check)
- `tests/functions/math/checks/b1_aggregates.sh` +90 −0 (plan check)
- `tests/functions/math/checks/b3_conditional.sh` +79 −0 (plan check)
- `tests/functions/math/__init__.py` +1 −0 (plan check)

Files landed by `wi-i5-math-2`:

- `src/functions/math/__init__.py` +143 −3

Files landed by `wi-i5-math-3`:

- `src/functions/math/__init__.py` +201 −2

Landing pull request: [exp-b #16](https://github.com/alebairos/sheet-exp-b/pull/16)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 26 h 55 min so far
- Loops: 4 (D2 plan 1, D6 landing 3)
- Waste: 37 min
- Size: 477 lines (+472 −5, 3 files, 401–1,000; tests 0 lines); plan check files laid over by land, not in the size: +273 −0, 4 files
