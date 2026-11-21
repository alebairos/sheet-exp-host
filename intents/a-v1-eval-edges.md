# Intent `a-v1-eval-edges`

## 1. Outcome

> Two Calc evaluation rules are missing. Observed vs LibreOffice: =C2:C3 in row 2 gives #VALUE! (Calc 3, implicit intersection); =IF(TRUE,1,A16) in A16 gives Err:522 (Calc 1), =IF(FALSE,B7,2) in B7 Err:522 (Calc 2), and B8 =IFERROR(B9,0) with B9 =B8 gives Err:522 for B8 (Calc 0) (G20, G22). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: in work · 3 work items · 2 bullets

## 2. What you will see

Two LibreOffice rules the engine lacked. A range used where one value is expected takes the cell in the formula's own row or column, as Calc does: =C2:C3 in row 2 gives C2, =B1:D1 in column C gives C1, and outside the range it is #VALUE!. A cell that refers to itself only through an IF or IFERROR branch that is not taken now computes, as in Calc: =IF(TRUE,1,A16) in A16 is 1, and =IFERROR(B9,0) with B9 =B8 is 0. Real circular references still show Err:522. The CLI, the page and every other formula behave as before.

- No media: an engine-only change; the checks' Calc-computed cases and today's red output are the evidence (tests/eval/checks/a_v1_ee_calc.json on the plan branch)

## 3. Approach

Cause, as read in the code and run on main. (1) src/eval collapses a Range in an operator or as a cell's value with Range.collapse(), which only accepts a single cell. It never knows the formula's own position, so =C2:C3 in row 2 is #VALUE! (a-i3 deferred implicit intersection because 'it needs the cell position'). (2) src/recalc finds strongly connected components statically from the parse trees and marks every cell of a cycle Err:522 without evaluating it, so a self-reference that sits in an IF/IFERROR branch Calc never takes is still an error. IF and IFERROR also evaluate all their arguments eagerly.
Fix. WI 1 (implicit intersection, about 50 lines): evaluate_node/evaluate take the formula's position (sheet, column, row). recalc already knows each formula's key and passes it. _scalar(v, pos) intersects a Range in single-value places (operator operands, unary minus, %, the cell's final value) Calc's way: a single cell is itself; a one-column range takes the cell in the formula's row if inside; a one-row range takes the formula's column; anything else is #VALUE!. A range on another sheet intersects with the formula's own row or column (T!A2 =Data!C2:C3 is Data!C2). Function arguments keep receiving Ranges, so SUM(C2:C3) is unchanged. WI 2 (untaken branches, about 100 lines): IF evaluates its condition, then only the branch it takes; IFERROR evaluates its fallback only on an error. This is done in src/eval's _call by name, since src/functions is outside this scope, keeping the registered functions' results for the values. For a cyclic component, recalc no longer marks it wholesale. It evaluates the component's cells in Calc's order (sheet, then column, then row), computing a precedent in the same component on demand when it is read. A read of a cell still being computed gives Err:522 to that read, and each cell keeps the value it got: B8 =IFERROR(B9,0) is 0 and B9 =B8 stays Err:522. A component of plain references (E1/E2) still ends Err:522 everywhere. On-demand evaluation must not use Python recursion for long cycles (a-i4's lesson): an explicit stack, or a depth bound that falls back to Err:522. WI 3: tests/eval/test_eval_edges.py.

Beliefs:
- ran: on main, all 10 intersection cases that Calc computes give #VALUE!, and all 13 untaken-branch cases give Err:522. Settled by a_v1_ee_b1_intersect.sh and a_v1_ee_b2_branch.sh, both red on main.
- ran: LibreOffice Calc 26.8.1.1 headless (a_v1_ee_probe.py, read from a_v1_ee_calc.json): =C2:C3 is 3 in row 2 and #VALUE! in row 5; =B1:D1 is 20 in column C; a 2-D range is #VALUE!; =Data!C2:C3 on sheet T takes T's row; =IF(C2:C3>3,...) intersects inside the operator; =IF(TRUE,1,A16) in A16 is 1; =IFERROR(F1,7) in F1 is 7; B8/B9 give 0 and Err:522 while C8/C9 give 0 and 0. Settled by b1 and b2.
- ran: Calc's order inside a cycle is column-major by address, not entry order and not row-major. J2 =IFERROR(K1,0) with K1 =J2 gives 0 and Err:522 (row-major would start at K1). L2 entered before L1 still gives 0 and 0 (entry order would start at L2). N1 entered first with M2 =N1 gives 0 and 0 (column M before N). Settled by b2's J/K, L and M/N pairs.
- code: recalc passes each formula's key to its evaluation, and functions receive Ranges, so intersecting only in _scalar leaves SUM/COUNTIF/VLOOKUP unchanged. Settled by b1's =SUM(C2:C3) and the existing function checks in land.
- memory: Calc also intersects ranges passed to functions that take a single value (e.g. =ABS(C2:C3)). That needs src/functions and is out of this scope. Settled by: not claimed (no check).
- code: no prototype was built for this plan. The checks fix the expected results, and the WI split follows the two causes. Settled by b1 and b2 at land.

Learned from RECORD.md and the overlapping pages: a-i3 rejected implicit intersection 'now: it needs the cell position', and a-i4 noted 'cycle readers rely on propagation, so IFERROR(cycle_cell, x) returns x'. This plan supplies the position and replaces wholesale cycle marking with Calc's on-demand rule. a-i4 rejected recursive on-demand evaluation because it overflowed on a 10,000-cell chain, so the cycle evaluation must not recurse per cell; this is stated in the approach. Values come from running Calc, including order cases the review did not try (the first probe showed that B8/B9 and C8/C9 differ, so order had to be pinned). Overlap: a-v1-decimal-noise and a-v1-engine-failure also touch src/eval (operators, long chains), and a-v1-text-rules touches values. Whichever lands later carries both.

- **Reuses:** src/eval's _scalar/_binary/_call and Range, src/recalc's SCC detection (it still finds cycles; only what it does with them changes) and its per-formula keys, and the registered IF/IFERROR for their values.
- **Removes:** Wholesale Err:522 marking of every cell in a cycle, and eager evaluation of IF's untaken branch and IFERROR's unused fallback.
- **Rejected:** Iterative calculation (Calc's option, off by default): out of scope. Evaluating every cycle cell once in entry order: Calc's results depend on its column-major order (J2/K1, L1/L2, M2/N1), so entry order gives wrong values. Intersecting inside each function: src/functions is outside this scope, and the bullets name single-value places, which operators and cell values cover. Treating any range as its first cell: Calc gives #VALUE! outside the range and for 2-D ranges.

## 4. Work items

### `wi-a-v1-eval-edges-1`: Implicit intersection

The evaluator knows each formula's cell and, where one value is expected, takes from a range the cell in the formula's row or column as Calc does (#VALUE! outside it or for a 2-D range), so =C2:C3 in row 2 gives C2.

Status: landed (`03bcf7aa5657`)

**The passing review noted:** > PASS. Reviewed commit 31fc901 (wi/wi-a-v1-eval-edges-1) against plan 327bfff (base 5ed792b). Diff: src/eval/__init__.py, src/recalc/__init__.py (one line) and tests/recalc/test_recalc.py, all inside the path scope.
> Verify, rerun: ac-ee-b1 tests/eval/checks/a_v1_ee_b1_intersect.sh passes on the WI ("16 formulas") and fails on base (T!A1/A3/B5 #VALUE!, Calc 3/4/10). ./test.sh: OK.
> Per AC (b1):
> - Range.collapse(pos) (src/eval/__init__.py:85-101) takes the cell in the formula's row for a one-column range and in its column for a one-row range; outside the range, or with no position, it is #VALUE!.
> - _scalar passes pos at every single-value place: unary minus, %, both operands of a Binary, and the final value (evaluate_node).
> - recalc._evaluate passes the formula's own addr (src/recalc/__init__.py:240), and _position parses it.
> - Function arguments still get Ranges, so SUM(C2:C3) is unchanged, but expressions inside arguments intersect.
> The test edit at tests/recalc/test_recalc.py:22-28 replaces an assertion that pinned the old #VALUE! for =A1:A3 in row 1. The new values (B1 0, B2 =A1:A3*2 gives 6, B5 #VALUE!) follow Calc's rule. It is legitimate, not a weakened test.
> My own LibreOffice 26.8.1.1 probe (headless UNO, a copy of a_v1_ee_probe.py with a new book; Data A1:C3 = 1..9, sheet T): 13 in-scope cases match Calc exactly:
> - =SUM(A1:A3*2) in row 2 gives 8; =A1:A3^2 in row 1 gives 1; =E1:E3 on a blank gives 0; =A1:A3+B1:B3 in row 3 gives 15.
> - =(A1:A3) gives 4; =A1:A3% gives 0.04; =A1:C1 in column A gives 1; =A1:C1*A1:A3 in B5 gives #VALUE!.
> - From sheet T: =Data!A1:C3 in B2 gives 5 (a 2-D range intersected on both axes from another sheet), and in D2 and B4 #VALUE!; =Data!A1:A3 gives 1; =Data!A1:C3*1 in B3 gives 8.
> Gap for the verdict, not blocking this WI because the plan excludes it ("Calc also intersects ranges passed to functions that take a single value ... out of this scope, not claimed"):
> - A range passed straight to a function that takes one value is still #VALUE!, where Calc intersects it: =ABS(A1:A3) in row 3 (Calc 7), =ROUND(A1:A3,0) in row 2 (Calc 4), =LEN(E1:E3) (Calc 0) and =IF(A1:A3,"y","n") in row 2 (Calc "y").
> - Bullet b1's wording ("a range used where one value is expected") reads as covering these too. The human should know the bullet is met only for operators and cell values.
> - IF's condition could be intersected in WI 2, which moves IF into _call by name.
> - (SUMPRODUCT is not a SPEC function, so #NAME? is expected.)
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ee-b1` | b1 | `tests/eval/checks/a_v1_ee_b1_intersect.sh` | red | — |

### `wi-a-v1-eval-edges-2`: Untaken branches don't make cycles

IF and IFERROR evaluate only the argument they use, and cells in a cycle are computed on demand in Calc's column-major order, a read of a cell still in progress being Err:522, so self-references through untaken branches give Calc's values.

Status: landed (`24bf5780a006`) · depends on `wi-a-v1-eval-edges-1`

**The passing review noted:** > PASS. Reviewed 8dff1d3 (src/eval, src/recalc, tests/recalc/test_recalc.py; +165 -14) on main 2070717, which already has WI-1. I used the plan's checks (327bfff).
> 
> - ac-ee-b2 (tests/eval/checks/a_v1_ee_b2_branch.sh): "ok b2: self-references through untaken branches match LibreOffice on 20 formulas". Red on main: Cyc!M2 =N1 gives Err:522, Calc 0.
> - WI-1's b1 check still passes: "ok b1: implicit intersection ... 16 formulas". So do a3_b1/b2/b3 and every other check script in tests/*/checks (20 scripts; the a-i4 10,000-cell checks among them). ./test.sh: 82 tests OK.
> - Code. src/eval/__init__.py:233-252: IF and IFERROR get their branches as _Unevaluated and evaluate only the one the registered function returns. This matches logic.py:69-89, which returns args[1], args[2] or the fallback as is; a missing branch still gives BLANK. src/recalc/__init__.py:286-321: a cyclic component is evaluated in (sheet tab, column, row) order. A pending read raises _Pending (a BaseException, so no function swallows it) and the reader restarts on an explicit stack, with no Python recursion. A read of a BUSY cell gives Err:522.
> - Held-out fidelity: 36 formulas on two sheets, computed in LibreOffice 26.8 through the plan's UNO probe with my own BOOK. All 36 match on the WI; main gets 22 wrong. They include: a 3-cell cycle with IFERROR in the middle (C1/C2 9, C3 Err:522); nested IF(TRUE,IF(FALSE,D1,2),D1) = 2; IF(TRUE,0,SUM(E1:E3)) with E2 =E1+1; a cycle across sheets (P!F1 =Q!A1, Q!A1 =IFERROR(P!F1,0): both 0); a non-cycle reader of a cycle (G1 =C1+1 is 10); IFERROR(1/0,J1) taking the self branch (Err:522); IF(FALSE,K1) is FALSE; AND(FALSE,M1) is Err:522 (not lazy, as in Calc); a 5-cell chain through IFERROR (all 1); IF(ISERROR(R2),3,R2) is 3; SUM(S2:S3) over two IFERROR readers is 3; IF(TRUE,5,C1)*2 is 10.
> - Incremental: Workbook.set making, breaking and remaking a cycle (B1 =A1, then 5, then =A1, then A1 =IF(TRUE,7,B1)) gives the right values each time.
> - Speed. A 10,000-cell cycle through IFERROR takes 0.26 s (base 0.17 s), in both directions.
> - Note, not a fail (nfr: none beyond Calc and the existing tests): one formula that reads k cells of its own component which are still pending restarts k times, so it is quadratic. A1 =IFERROR(SUM(B1:Bk),0) with every B =A1+1 takes 0.58 s at k=1000 and 3.2 s at k=3000 (base 0.06 s and 0.10 s). The values are right (A1 0, Bs Err:522). Such books are rare. If it matters, evaluate the pending precedents of a range before restarting the reader. Worth a test in WI-3 or a follow-up.
> - Scope: src/eval, src/recalc and tests/recalc are all in the intent's scope.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ee-b2` | b2 | `tests/eval/checks/a_v1_ee_b2_branch.sh` | red | — |

### `wi-a-v1-eval-edges-3`: Product tests for evaluation edges

Adds tests/eval/test_eval_edges.py, run by ./test.sh, covering implicit intersection and the untaken-branch and cycle-order cases, so the product keeps this behaviour.

Status: landing (`85df36ac019e`) · depends on `wi-a-v1-eval-edges-2`

**The passing review noted:** > PASS. Reviewed 2004ee4 (tests/eval/test_eval_edges.py) on main 1969234, which already has WI-1 and WI-2. I used the plan's checks (327bfff).
> 
> - ac-ee-suite (tests/eval/checks/a_v1_ee_suite.sh): "ok the product's evaluation-edge tests run and pass (11)". Red on base: "no tests in tests/eval/test_eval_edges.py". b1/b2 checks pass. ./test.sh: 110 tests OK.
> - The expected values are not hand-written. I checked programmatically that BOOK == a_v1_ee_calc.json["book"] and CALC == ["results"]: both True. Every Calc result is asserted by some test (:124-157): Data 12 of 12, T 4 of 4, Cyc 20 of 20.
> - The tests pin both WIs. With src/eval and src/recalc from before WI-1 (31fc901^): FAILED (failures=7). With WI-1 but not WI-2 (31fc901): FAILED (failures=3), the untaken-branch tests. With WI-2: OK.
> - Optional nit: LongCycleTest (:160-169) accepts 0 or Err:522 for every cell, so it only guards against overflow. The engine gives 0 for all 5000 cells: A1 starts, A5000 reads A1 while it is busy, IFERROR gives 0, and that flows back. Asserting all 0 would pin the order too, but that value is not from Calc, so leaving it loose is defensible.
> - Carried from my WI-2 review: the quadratic restart when one formula reads many pending cells of its own cycle (3.2 s at 3000 cells) has no test here. It is a follow-up candidate, not this WI's.
> - Scope: tests/eval only, inside the intent's scope. The judge is answered elsewhere.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ee-suite` | b1, b2 | `tests/eval/checks/a_v1_ee_suite.sh` | red | — |
| `ac-ee-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through ./engine as shipped, does a user who writes =C2:C3-style formulas next to their data, or guards a self-reference with IF/IFERROR (e.g. =IF(A1="",0,B1+B1) patterns), get the numbers they would expect from a spreadsheet instead of #VALUE! or Err:522? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | a range used where one value is expected takes the cell in the formula's row or column, as LibreOffice does, on cases computed by LibreOffice | `tests/eval/checks/a_v1_ee_b1_intersect.sh` — |
| not yet | b2 | a self-reference through a branch IF or IFERROR does not take gives LibreOffice's value, not Err:522, on cases computed by LibreOffice | `tests/eval/checks/a_v1_ee_b2_branch.sh` — |

## 5. Out of scope and risks

- **Out of scope:** iterative calculation
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/eval/**`, `exp-a:src/recalc/**`, `exp-a:tests/eval/**`, `exp-a:tests/recalc/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-eval-edges-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-eval-edges-1` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-v1-eval-edges-2` | `impl-a1@alebairos` |
| Reviewed `wi-a-v1-eval-edges-2` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-v1-eval-edges-3` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-eval-edges-3` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-v1-eval-edges-1`:

- `src/eval/__init__.py` +54 −22
- `tests/eval/checks/a_v1_ee_probe.py` +53 −0 (plan check)
- `tests/eval/checks/a_v1_ee_suite.sh` +27 −0 (plan check)
- `tests/eval/checks/a_v1_ee_common.py` +26 −0 (plan check)
- `tests/eval/checks/a_v1_ee_b1_intersect.sh` +11 −0 (plan check)
- `tests/eval/checks/a_v1_ee_b2_branch.sh` +11 −0 (plan check)
- `tests/recalc/test_recalc.py` +6 −2 (test)
- `src/recalc/__init__.py` +1 −1
- `tests/eval/checks/a_v1_ee_calc.json` +1 −0 (plan check)

Files landed by `wi-a-v1-eval-edges-2`:

- `src/recalc/__init__.py` +88 −7
- `tests/recalc/test_recalc.py` +46 −0 (test)
- `src/eval/__init__.py` +31 −7

Landing pull request: [exp-a #29](https://github.com/alebairos/sheet-exp-a/pull/29)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 2 h 50 min so far
- Loops: 0
- Waste: 0 min
- Size: 211 lines (+174 −37, 6 files, ≤400; tests 54 lines); plan check files laid over by land, not in the size: +129 −0, 6 files
