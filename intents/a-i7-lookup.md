# Intent `a-i7-lookup`

## 1. Outcome

> VLOOKUP, INDEX and MATCH compute as in Calc, exact and approximate, with #N/A and #REF! where Calc gives them

Kind: Feature · State: awaiting the verdict · 1 work item · 2 bullets

## 2. What you will see

VLOOKUP, INDEX and MATCH work in formulas exactly as Calc computes them: =VLOOKUP("apple",E1:F5,2,0) finds the row, =VLOOKUP(35,A1:C5,2) takes the nearest smaller key in a sorted table, =INDEX(A1:C5,MATCH(40,A1:A5,0),2) combines the two, and a missing key is #N/A. Calc's habits included: text keys match case-insensitively with * and ? wildcards, a key typed as text ("30") finds the number 30, duplicate keys give the first row when exact and the last when approximate, INDEX outside its range is #REF!, and a VLOOKUP column past the table is Calc's Err:502. The media is Calc's answer sheet: the 104 formulas the checks run, each with what LibreOffice returned.

- [a-i7-lookup/README.md](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/README.md)
- [a-i7-lookup/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/calc-answers.md)
- [a-i7-lookup/lk.out.json](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/lk.out.json)
- [a-i7-lookup/lk.py](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/lk.py)
- [a-i7-lookup/probe.py](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/probe.py)
- [a-i7-lookup/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/gencheck.py)

## 3. Approach

One module, src/functions/lookup/lookup.py, registering VLOOKUP, INDEX and MATCH with @register (a-i0's registry finds it, no shared file edited) on a-i3's calling convention: the table arrives as a src.eval.Range (book, sheet, corners), so the functions read cells through it and INDEX can return a one-cell Range (a reference, as Calc does, so =INDEX(...)&"?" and later ISBLANK see the cell). Shared core first, used by all three: a matcher for the lookup value (numbers and numeric text against numbers, text case-insensitively with * ? ~ wildcards, booleans as numbers, blanks never), an exact scan returning the first hit, and an approximate binary-free scan of a sorted vector returning the last position whose key is <= the value (same type only), #N/A when none. VLOOKUP: column index through to_number and truncated, outside 1..width Err:502, mode any non-zero approximate, text mode #VALUE!. MATCH: type truncated, 0 exact, 1 approximate, other values Err:504; a range that is neither one row nor one column Err:504. INDEX: row and column truncated, a one-row range takes a single index as the column, 0 or a missing index on a two-dimensional range #VALUE!, negative Err:502, past the edge #REF!. Errors in the lookup value or indices pass through. Unit tests in tests/functions/lookup.

- **Reuses:** src.functions.register and registry() (a-i0); src.eval's Range and calling convention (a-i3), including returning a Range; src.values Values, to_number and compare (a-i2).
- **Removes:** none
- **Rejected:** Excel's results (#REF! for a VLOOKUP column past the table, no numeric-text match): the suite is computed by LibreOffice. A binary search for approximate mode: Calc's answers on duplicates (last of equal keys) and the small tables in workbooks do not need it; a linear scan is simpler and exact. MATCH type -1 and HLOOKUP/XLOOKUP: outside the bullets and SPEC's 40 functions. Mapping Err:502/Err:504 to #VALUE!: kept as Calc displays them, as a-i4, a-i5 and a-i6 do.

## 4. Work items

### `wi-a-i7-lookup-1`: Lookup: VLOOKUP, INDEX, MATCH

Add src/functions/lookup/lookup.py with VLOOKUP, INDEX and MATCH on one shared matcher (exact with wildcards, approximate on sorted keys) returning Calc's results and errors, so workbooks can look values up in tables.

Status: landed (`dcee02bc1209`)

**The passing review noted:** > PASS (attempt 2). Attempt 1 passed review and its landing aborted on a rejected push, not on tests. Attempt 2 (fd05d6c) changes only tests/functions/lookup/test_lookup.py (+50 lines): 31 MATCH type -1 cases on descending data, ties and text included. src/functions/lookup/lookup.py is unchanged from ac2d2b8, so the attempt-1 evidence per AC still holds (VLOOKUP lookup.py:164, MATCH :145, INDEX :194, _exact :69, _find :93).
> Reran verify on fd05d6c (worktree): a7_b1_vlookup.sh "ok b1: 42 cases match Calc", a7_b2_index_match.sh "ok b2: 62 cases match Calc"; base c21e65b red as before; ./test.sh OK (new tests included).
> Independently re-derived 8 of the new pinned values with LibreOffice 26.8.1.1 headless on the same fixture: MATCH(2.5,F1:F5,-1)=4, MATCH(3,F1:F5,-1)=4, MATCH(5,F1:F5,-1)=2, MATCH("bb",D1:D5,-1)=3, MATCH("0",D1:D5,-1)=5, MATCH(3,D1:D5,-1)=#N/A, MATCH(0,B1:B5,-1)=5, MATCH(6,B1:B5,-1)=#N/A: all equal to the test and to the engine. My attempt-1 note (2) is answered: -1 matches Calc on descending data; on non-descending data it still differs and that is documented in the test, which is fine since b2 covers types 0 and 1. Note (1) (VLOOKUP onto an empty cell shows 0, Calc shows empty) stands for the Gm, outside this scope.
> Process note: the attempt-2 commit is authored under the human's name, not an implementer id (attempt 1 was impl-a2@alebairos); the review is of the code, and nothing in the diff is affected.
> Scope: one test file inside tests/functions/lookup; no check edited.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a7-b1` | b1 | `tests/functions/lookup/checks/a7_b1_vlookup.sh` | red | pass |
| `ac-a7-b2` | b2 | `tests/functions/lookup/checks/a7_b2_index_match.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | VLOOKUP exact and sorted approximate match Calc | `tests/functions/lookup/checks/a7_b1_vlookup.sh` pass |
| PASS | b2 | INDEX and MATCH (types 0 and 1) match Calc, errors included | `tests/functions/lookup/checks/a7_b2_index_match.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/functions/lookup/**`, `exp-a:tests/functions/lookup/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i7-lookup-1` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-i7-lookup-1` | `rev-a@alebairos` (passed attempt 2) |

Product checks:

- `tests/functions/lookup/checks/a7_b1_vlookup.sh`: pass
- `tests/functions/lookup/checks/a7_b2_index_match.sh`: pass

Outcome report:

- **Built:** Landed on exp-a main (dcee02b, attempt 2 after one failed attempt): src/functions/lookup/lookup.py, which registers VLOOKUP, INDEX and MATCH with the evaluator, plus tests/functions/lookup. I re-ran both checks on landed main and they pass: a7_b1_vlookup (42 cases match Calc) and a7_b2_index_match (62 cases match Calc), the 104 LibreOffice answers in the media. The full suite also passes. A live ./engine run on a 4-row sorted table gave: =VLOOKUP(35,A1:B4,2) "c" (nearest smaller key), =VLOOKUP("ap*",E1:F2,2,0) 1 (case-insensitive wildcard on "Apple"), =INDEX(A1:B4,MATCH(40,A1:A4,0),2) "d", =VLOOKUP(99,…,0) #N/A, =INDEX(A1:B4,9,1) #REF!, =VLOOKUP("30",…,0) "c" (a text key finds the number), and =VLOOKUP(10,A1:B4,5,0) Err:502. Each matches the plan's description of Calc.
- **Advice:** Try it in a clone of exp-a: pipe a workbook with a small sorted table and a few VLOOKUP/INDEX/MATCH formulas into ./engine -, and compare the results with calc-answers.md in the media, which lists the 104 formulas and what LibreOffice returned for each. Other functions are outside this scope. Both bullets hold on landed code, so Met fits.
- [a-i7-lookup/README.md](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/README.md)
- [a-i7-lookup/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/calc-answers.md)
- [a-i7-lookup/lk.out.json](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/lk.out.json)
- [a-i7-lookup/lk.py](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/lk.py)
- [a-i7-lookup/probe.py](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/probe.py)
- [a-i7-lookup/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/da01a8a372d9861f197036aa2f4435f75c6603d6/a-i7-lookup/gencheck.py)

Files landed by `wi-a-i7-lookup-1`:

- `src/functions/lookup/lookup.py` +213 −0
- `tests/functions/lookup/test_lookup.py` +113 −0 (test)
- `tests/functions/lookup/checks/a7_b2_index_match.sh` +111 −0 (plan check)
- `tests/functions/lookup/checks/a7_b1_vlookup.sh` +90 −0 (plan check)
- `tests/functions/lookup/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #14](https://github.com/alebairos/sheet-exp-a/pull/14)

## 7. The decision

**Verdict:a-i7-lookup**: A decision: show your human its options

- Met: `cooknship decide --answer Verdict:a-i7-lookup --option met`
- Partially met: unmet bullets park as follow-ups: `cooknship decide --answer Verdict:a-i7-lookup --option partially`
- Not met: every unmet bullet parks as a follow-up: `cooknship decide --answer Verdict:a-i7-lookup --option not_met`

## 8. Metrics

- Lead time: 22 h 06 min so far
- Loops: 1 (D6 landing 1)
- Waste: 17 min
- Size: 213 lines (+213 −0, 3 files, ≤400; tests 113 lines); plan check files laid over by land, not in the size: +201 −0, 2 files
