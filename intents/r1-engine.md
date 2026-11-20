# Intent `r1-engine`

## 1. Outcome

> The engine computes whole workbooks end to end through the CLI: formulas, functions and recalculation together

Kind: Feature · State: in work · 1 work item · 2 bullets

## 2. What you will see

Whole workbooks computed end to end through the engine CLI, as the hidden suite will: a three-sheet workbook (Data, Summary, Calc) that uses all 40 functions together, references across sheets in both directions, numeric text, a boolean, a failed lookup caught by IFERROR and a division by zero; and a workbook with 100-formula chains where a #DIV/0! at A40 flows to A100 and through COUNT/SUM, a #N/A from VLOOKUP flows through 100 text formulas on another sheet, and a chain written bottom-up still computes in dependency order. Every cell equals what LibreOffice Calc gave for the same workbook. The media is Calc's answer sheet for every formula. The plan checks load those workbooks from readable JSON siblings (r1_b1_book.json / r1_b1_calc.json and r1_b2_book.json / r1_b2_calc.json) next to the shell scripts.

- [r1-engine/README.md](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/README.md)
- [r1-engine/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/calc-answers.md)
- [r1-engine/books.json](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/books.json)
- [r1-engine/calc.json](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/calc.json)
- [r1-engine/books.py](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/books.py)
- [r1-engine/bookprobe.py](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/bookprobe.py)
- [r1-engine/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/gencheck.py)

## 3. Approach

HITL Clarified again: section 5 OOS cannot be amended in the ledger, so it will no longer reject on that ground; section 3 of this plan governs out_of_scope as: the UI; changes outside the three measured gaps (ROUND, COUNTIF "<>", COUNT over errors) and the e2e suite; no rewrites of function packages and no edits outside the path scope. Keep this plan and re-certify. Both check scripts already end with sys.exit(1) on failure and print("ok") like each other. WI: fix ROUND / COUNTIF <> / COUNT-over-error in src/functions/math and src/eval, then add tests/e2e/engine books + unittest discovery. Checks load pretty-printed r1_b*_book.json / r1_b*_calc.json siblings (plan oid on host plan/r1-engine).

- **Reuses:** The engine CLI (./engine, src.cli); existing math aggregates/rounding and eval; Calc workbooks from evidence/r1-engine; the split JSON pins beside the checks.
- **Removes:** tests/e2e/.gitkeep may be replaced by the suite; nothing else.
- **Rejected:** Rejecting again on stale section 5 OOS: HITL Clarified that ground is withdrawn. Tests-only suite: Gate rejected earlier because main mismatches the pins. Separate Defects for the three gaps: HITL Clarify said keep this plan.

## 4. Work items

### `wi-r1-engine-1`: Calc pins then e2e suite

Fix the measured ROUND, COUNTIF <>, and COUNT-over-error gaps so the embedded Calc workbooks match, then add tests/e2e/engine so ./test.sh runs those whole-workbook checks against LibreOffice answers.

Status: landing (`995feadc6695`)

**Flagged:** outside the scope: exp-b:tests/e2e/.gitkeep

**The passing review noted:** > PASS review of wi-r1-engine-1 (commit 31773a2).
> 
> AC b1 (ac-r1-b1 / tests/e2e/engine/checks/r1_b1_workbooks.sh): re-ran; printed ok, exit 0. Covers multi-sheet mixed-function workbook vs Calc pins (r1_b1_book.json / r1_b1_calc.json) and product books under tests/e2e/engine/books/. Implementation: COUNT rewrite src/functions/math/__init__.py:88, ROUND Decimal via format(.15g) :168, COUNTIF <> for blank/number/bool vs text criterion :384. Product suite test tests/e2e/engine/test_engine.py:42 passed under the check's discover.
> 
> AC b2 (ac-r1-b2 / tests/e2e/engine/checks/r1_b2_chain.sh): re-ran; printed ok, exit 0. Covers 100-formula chains with error propagation matching Calc (r1_b2_book.json / r1_b2_calc.json) and books/chain.json.
> 
> Outside scope (flagged, not refused): exp-b:tests/e2e/.gitkeep deleted. Belongs: design.removes says it may be replaced by the suite; path is parent of tests/e2e/engine/, not inside engine/ subtree. No other paths outside scope.
> 
> No src/eval changes; the three measured gaps are closed in math as above. ./test.sh (scripts/test) also green on this tip.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r1-b1` | b1 | `tests/e2e/engine/checks/r1_b1_workbooks.sh` | red | — |
| `ac-r1-b2` | b2 | `tests/e2e/engine/checks/r1_b2_chain.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | multi-sheet workbooks mixing every function group compute as Calc does | no landed check |
| not yet | b2 | a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the UI; changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:tests/e2e/engine/**`, `exp-b:tests/e2e/__init__.py`, `exp-b:tests/__init__.py`, `exp-b:src/functions/math/**`, `exp-b:src/eval/**`
- **`wi-r1-engine-1`**: outside the scope: exp-b:tests/e2e/.gitkeep

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-r1-engine-1` | `impl-1@alebairos` |
| Reviewed `wi-r1-engine-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Landing pull request: [exp-b #18](https://github.com/alebairos/sheet-exp-b/pull/18)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 30 h 33 min so far
- Loops: 6 (D1 spec 2, D2 plan 4)
- Waste: 2 h 47 min
- Size: nothing landed yet
