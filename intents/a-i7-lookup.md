# Intent `a-i7-lookup`

## 1. Outcome

> VLOOKUP, INDEX and MATCH compute as in Calc, exact and approximate, with #N/A and #REF! where Calc gives them

Kind: Feature · State: in work · 1 work item · 2 bullets

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

Status: accepted

**The passing review noted:** > PASS. Reran verify on the WI commit ac2d2b8 (worktree): a7_b1_vlookup.sh "ok b1: 42 cases match Calc", a7_b2_index_match.sh "ok b2: 62 cases match Calc"; on the plan commit c21e65b both fail (42/42 and 62/62 differ). ./test.sh OK.
> - ac-a7-b1 (b1): src/functions/lookup/lookup.py:164 VLOOKUP reads the first column through the Range, exact mode via _exact (lookup.py:69: numbers/booleans by value, text case-insensitive with * ? ~, numeric text also finds the number), sorted mode via _find (lookup.py:93, last key <= value, same type only, end of an equal run); column truncated, outside 1..width Err:502 (lookup.py:185).
> - ac-a7-b2 (b2): MATCH (lookup.py:145) types 0/1, 2-D range Err:504; INDEX (lookup.py:194) returns a Range so the result is a reference, one-row range takes the single index as the column, 0 on a 2-D range #VALUE!, negative Err:502, past the edge #REF!.
> - Cross-checked 26 extra formulas against LibreOffice 26.8.1.1 headless on my own fixture: all agree (INDEX(A1:B4,0,0) #VALUE!, INDEX(A1:B4,-1,1) Err:502, INDEX(A1:A4,5) #REF!, VLOOKUP(1,..,1.9,0) truncates, VLOOKUP(TRUE,..) finds 1, MATCH("X",..,0) case-insensitive, missing lookup value #N/A, VLOOKUP(..)&"|" gives "|") except the two below.
> Notes, not blocking:
> (1) VLOOKUP landing on a blank cell: Calc shows the cell as EMPTY (csv ''), while ISBLANK of it is TRUE and +1 gives 1; =B2 and =INDEX(B1:B4,2) on the same blank show 0. The engine returns 0 for all three. lookup.py:191 returns the Blank Value correctly; the top-level Blank->0 conversion lives in src/values / src/eval, outside this intent's scope, and Calc's "empty result" needs a value kind the model does not have. Worth a separate Defect for the Gm (the hidden suite may well have a VLOOKUP onto an empty cell).
> (2) MATCH type -1 is implemented (lookup.py:107) though the design says types other than 0 and 1 give Err:504 and b2 covers only 0 and 1. It disagrees with Calc on non-descending data: A1:A4 = 1,2,3,"x", =MATCH(2,A1:A4,-1) gives 2, Calc #N/A. Harmless to b2; either pin -1 against Calc or follow the design.
> Scope: src/functions/lookup/lookup.py, tests/functions/lookup/__init__.py, tests/functions/lookup/test_lookup.py, all inside the scope; no check edited.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a7-b1` | b1 | `tests/functions/lookup/checks/a7_b1_vlookup.sh` | red | — |
| `ac-a7-b2` | b2 | `tests/functions/lookup/checks/a7_b2_index_match.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | VLOOKUP exact and sorted approximate match Calc | no landed check |
| not yet | b2 | INDEX and MATCH (types 0 and 1) match Calc, errors included | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/functions/lookup/**`, `exp-a:tests/functions/lookup/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i7-lookup-1` | `impl-a1@alebairos` |
| Reviewed `wi-a-i7-lookup-1` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 21 h 21 min so far
- Loops: 1 (D6 landing 1)
- Waste: 15 min
- Size: nothing landed yet
