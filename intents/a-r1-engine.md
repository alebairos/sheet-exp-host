# Intent `a-r1-engine`

## 1. Outcome

> The engine computes whole workbooks end to end through the CLI: formulas, functions and recalculation together

Kind: Feature · State: in work · 1 work item · 2 bullets

## 2. What you will see

Whole workbooks computed end to end through the engine CLI, as the hidden suite will: a three-sheet workbook (Data, Summary, Calc) that uses all 40 functions together, references across sheets in both directions, numeric text, a boolean, a failed lookup caught by IFERROR and a division by zero; and a workbook with 100-formula chains where a #DIV/0! at A40 flows to A100 and through SUM, a #N/A from VLOOKUP flows through 100 text formulas on another sheet, and a chain written bottom-up still computes in dependency order. Every cell equals what LibreOffice Calc gave for the same workbook. The media is Calc's answer sheet for every formula.

- [a-r1-engine/README.md](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/README.md)
- [a-r1-engine/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/calc-answers.md)
- [a-r1-engine/books.json](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/books.json)
- [a-r1-engine/calc.json](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/calc.json)
- [a-r1-engine/books.py](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/books.py)
- [a-r1-engine/bookprobe.py](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/bookprobe.py)
- [a-r1-engine/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/gencheck.py)

## 3. Approach

The engine on main already computes both workbooks exactly as Calc (0 mismatches, measured over every cell), so no engine code changes (out of scope, and forbidden in the WI). One WI adds the product's own e2e suite: tests/e2e/__init__.py and tests/e2e/engine/__init__.py so ./test.sh discovers it, workbooks in tests/e2e/engine/books/<name>.json with Calc's answers in <name>.calc.json (the evidence's books.json/calc.json can be copied as is), and a unittest that runs ./engine on each workbook and compares every cell (numbers within 1e-9). The checks hold their own copy of the two workbooks and Calc's answers, in files next to the scripts (tests/e2e/engine/checks: a_r1_b*_book.json and _calc.json, compact, one line per sheet; the shared helpers in a_r1_common.py and a_r1_chain.py, so every check file stays under 80 lines) and also require the product suite to have them: workbooks covering all 40 functions with a cross-sheet formula (b1), and one with a 100-long chain whose Calc answers carry an error (b2), all computing as their .calc.json says and the e2e tests passing.

- **Reuses:** The engine CLI (./engine, src.cli) as it is; the Calc probe over UNO from a-i5/a-i7's evidence, extended to load a whole workbook and read every cell.
- **Removes:** tests/e2e/README.md's placeholder may be replaced by a note on the suite; nothing else.
- **Rejected:** Fixing behaviour here: none is wrong, and changing the parts' code is out of scope. Checks that only run the embedded workbooks: they pass on base, so they cannot prove this intent's work; requiring the product's own e2e suite is what this intent adds. Comparing against Excel or hand-computed values: the suite is LibreOffice's. A per-formula probe (append formulas to a fixture): it misses dependency order and propagation across a whole workbook, which is the point of b2.

## 4. Work items

### `wi-a-r1-engine-1`: End-to-end workbook tests

Adds the product's end-to-end suite under tests/e2e/engine: whole multi-sheet workbooks (every function group, cross-sheet formulas, and a 100-formula chain carrying an error) run through ./engine and compared cell by cell with LibreOffice Calc's answers, so ./test.sh guards the engine as a whole.

Status: accepted

**The passing review noted:** > PASS, wi-a-r1-engine-1 @ cdadae2 (plan 6dbab0a). Verify rerun in clean worktrees of both commits.
> - The diff is 7 files, all inside the scope (exp-a:tests/e2e/engine/**, tests/e2e/__init__.py). No engine code changed, and no check file is touched (git diff 6dbab0a..cdadae2 lists only the books, the two __init__.py files and test_workbooks.py).
> - Base (6dbab0a): both checks are red. a_r1_b1_workbooks.sh fails with "no product workbooks" and "no tests under tests/e2e/engine". a_r1_b2_chain.sh fails with "no ... chain of 100 formulas with an error" and the same missing tests.
> - ac-r1-b1 (b1), tests/e2e/engine/checks/a_r1_b1_workbooks.sh: green on the WI ("ok"). books/mixed.json has Data, Summary and Calc sheets, cross-sheet refs both ways, and calls all 40 SPEC functions (asserted at test_workbooks.py:68-72). Every cell matches mixed.calc.json, including #N/A, #DIV/0!, #VALUE!, numeric text and booleans.
> - ac-r1-b2 (b2), tests/e2e/engine/checks/a_r1_b2_chain.sh: green on the WI ("ok"). In books/chain.json the longest formula chain is 105. Sheet1 A40 =A39/(A1-1) gives #DIV/0!, which flows through A41..A100 and SUM(A1:A100) (B2), and IFERROR catches it (B4 "caught"). Sheet2 A1 VLOOKUP("nope",...) gives #N/A through 100 UPPER formulas (A2..A100). C1..C100 is written bottom-up and gives 101. Asserted at test_workbooks.py:74-80.
> - Suite: ./test.sh (scripts/test, unittest discover -s tests) runs 66 tests, all OK, 2 of them new from tests/e2e/engine.
> - Independent Calc check: I rebuilt both product workbooks as .fods (OpenFormula) and recalculated them with LibreOffice headless (soffice 26.8, CSV export at full precision, text quoted). All 534 answer cells match the committed .calc.json, 119 in mixed and 415 in chain, 0 mismatches. Text versus number agrees too: Summary!C6 is the text "1.97" and Data!C9 the text "6". So the answers really are Calc's and were not generated by the engine.
> - Nit, not blocking: test_workbooks.py repeats the 40-function list from the checks. It compares only the cells listed in .calc.json, which cover every cell of both books, so nothing is skipped.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r1-b1` | b1 | `tests/e2e/engine/checks/a_r1_b1_workbooks.sh` | red | — |
| `ac-r1-b2` | b2 | `tests/e2e/engine/checks/a_r1_b2_chain.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | multi-sheet workbooks mixing every function group compute as Calc does | no landed check |
| not yet | b2 | a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the UI; changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:tests/e2e/engine/**`, `exp-a:tests/e2e/__init__.py`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-r1-engine-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-r1-engine-1` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 24 h 54 min so far
- Loops: 5 (D1 spec 1, D2 plan 3, D6 landing 1)
- Waste: 33 min
- Size: nothing landed yet
