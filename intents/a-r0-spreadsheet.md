# Intent `a-r0-spreadsheet`

## 1. Outcome

> A spreadsheet that computes like LibreOffice on real workbooks: realistic workbooks (a budget, a grade sheet, a lookup table) compute and display as Calc does

Kind: Feature · State: in work · 2 work items · 2 bullets

## 2. What you will see

Three realistic workbooks become part of the product's own test suite: a household budget (Summary, Income, Expenses), a grade sheet (Grades, Scale) and an order sheet (Orders, Catalog), 7 sheets and 182 formulas between them, using all 40 of SPEC's functions and cross-sheet references. ./test.sh computes each through the CLI and compares every cell with what LibreOffice Calc computed, and opens each in headless Chrome: the first sheet shows as Calc shows it, a formula reads as typed in the formula bar, and Save JSON gives the workbook back unchanged. The screenshots show the three workbooks in today's page.

- [a-r0-spreadsheet/README.md](https://github.com/alebairos/sheet-exp-host/blob/dfead4508dc930b9b46d9052512bce68d8198dd4/a-r0-spreadsheet/README.md)
- [a-r0-spreadsheet/1-budget.png](https://github.com/alebairos/sheet-exp-host/blob/dfead4508dc930b9b46d9052512bce68d8198dd4/a-r0-spreadsheet/1-budget.png)
- [a-r0-spreadsheet/2-grades.png](https://github.com/alebairos/sheet-exp-host/blob/dfead4508dc930b9b46d9052512bce68d8198dd4/a-r0-spreadsheet/2-grades.png)
- [a-r0-spreadsheet/3-orders.png](https://github.com/alebairos/sheet-exp-host/blob/dfead4508dc930b9b46d9052512bce68d8198dd4/a-r0-spreadsheet/3-orders.png)
- [a-r0-spreadsheet/bookprobe.py](https://github.com/alebairos/sheet-exp-host/blob/dfead4508dc930b9b46d9052512bce68d8198dd4/a-r0-spreadsheet/bookprobe.py)

## 3. Approach

Most value first: the engine and the page already compute and show all three workbooks as Calc does on main (checked: every cell matches), so the work is to pin that in the product's suite. WI 1: tests/e2e/workbooks/__init__.py, books/{budget,grades,orders}.json and .calc.json (copies of the plan's checks/a_r0_books.json and a_r0_calc.json, one workbook per file) and test_cli.py, a unittest that runs each book through ./engine - and compares every cell with the .calc.json (numbers within 1e-9 relative). WI 2: test_browser.py (and a Node script next to it) that serves web/io with serve.py, drives headless Chrome/Chromium ($CHROME first) over the DevTools pipe from Node's standard library, as tests/e2e/ui does, and walks open, display, formula bar and save for each book; skipped only without node or a browser. Each check runs its own walk too and also requires the product's test to exist, run and pass, so both are red on main today.

- **Reuses:** The engine CLI, web/io's page, serve.py, the grid and the formula bar as they are; tests/e2e/engine's way of comparing with Calc and tests/e2e/ui's way of driving the browser.
- **Removes:** none
- **Rejected:** Sheet tabs so every sheet shows in the browser: the page shows a workbook's first sheet only, and changing the parts' code is out of scope here; the workbooks are ordered so the first sheet is the one that reads the others (Summary, Grades, Orders), and the other sheets are checked through the CLI and through Save JSON. Generating Calc's answers at test time: LibreOffice is not on the land runner, so the answers are stored, computed once by LibreOffice headless (bookprobe.py on the evidence branch). Reusing tests/e2e/engine/books: those are synthetic mixes of every function, not workbooks a person would keep.

## 4. Work items

### `wi-a-r0-spreadsheet-1`: Three workbooks through the CLI

Adds a budget, a grade sheet and an order sheet with Calc's answers to the product's e2e suite, with a test that runs each through ./engine and compares every cell, so these real workbooks keep computing as Calc does.

Status: landed (`d3a6753ff0e3`)

**The passing review noted:** > PASS. ac-r0-b1 (b1): reran tests/e2e/workbooks/checks/a_r0_b1_cli.sh in a worktree of 629e643: "ok", exit 0. On the plan commit fe9dcd8 it exits 1 (no product books, no discoverable test_cli), so the base is red. Full ./test.sh on the WI: 71 tests OK, including the 4 new tests.e2e.workbooks.test_cli tests (budget/grades/orders match Calc, all 40 SPEC functions used). Evidence: the books/*.json and *.calc.json are byte-identical in content to the plan's a_r0_books.json / a_r0_calc.json (product_books() in a_r0_common.py passes). test_cli.py:47-53 runs each book through ./engine via stdin, and :37-41 compares numbers within 1e-9 relative and text/bool by exact type. :59-71 checks every cell, sheet order (:57) and a cross-sheet formula (:72). :87-92 pins all 40 SPEC functions. Independent check: I rebuilt the three books as .fods (wildcards on, as in a new Calc document) and recomputed them in LibreOffice 26.8 headless. All 441 stored Calc answers match (budget 152, grades 139, orders 150). Mutation: changing one stored answer (grades Grades!E3 +1e-6) makes test_grades_matches_calc fail, so the test has teeth. Scope: all 8 paths are under exp-a:tests/e2e/workbooks/** and no product code changed. Note for the human: the budget book's COUNTIF(E2:E7,"with*") relies on Calc's wildcard setting, which is on by default; with wildcards off, Calc gives 0. -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r0-b1` | b1 | `tests/e2e/workbooks/checks/a_r0_b1_cli.sh` | red | — |

### `wi-a-r0-spreadsheet-2`: The same workbooks in the browser

Adds a browser test that opens each of the three workbooks in the app page, checks its first sheet shows as Calc computes it, reads a formula in the formula bar and saves it back unchanged, so the page keeps handling real workbooks.

Status: landing (`4fc698577f4f`) · depends on `wi-a-r0-spreadsheet-1`

**The passing review noted:** > PASS. ac-r0-b2 (b2): reran tests/e2e/workbooks/checks/a_r0_b2_browser.sh in a worktree of 8df8a35 with local chromium. Result: "ok budget, grades and orders open, display and save in the browser" plus the product-test half "ok", exit 0. On the base 566787d (main after WI-1 landed) it exits 1 with "./test.sh discovers no tests in tests/e2e/workbooks/test_browser.py", so the base is red. Full ./test.sh on the WI: 75 tests OK. The 4 test_browser tests ran, none skipped, through the $CHROME wrapper. Evidence: test_browser.py:22-32 runs browser_walk.mjs per book (skipped only on exit 2 = no browser or no node). browser_walk.mjs:53 opens via DOM.setFileInputFiles on #open. :55-63 compares every cell of A1:H20 with books/<name>.shown.json, blanks included. :65-69 clicks the first formula cell with real mouse events and waits for the bar to read the formula as typed. :71-76 clicks #save-json and requires the download to equal the opened book. :77 fails on any page exception. books/*.shown.json equal the plan's checks/a_r0_shown.json. I checked them independently against books/*.calc.json: all 269 first-sheet cells agree (Summary 34, Grades 121, Orders 114). Mutation: changing grades.shown.json Grades!E3 to "69.71" makes test_grades_in_the_browser fail with "Calc shows 69.71, the grid 69.7". Scope: all 5 paths are under exp-a:tests/e2e/workbooks/** and no product code changed. Nits, not blocking: (1) test_shown_matches_calc (test_browser.py:46-54) only checks that shown.json covers the first sheet's cells, not that its values equal calc.json, so the name says more than it checks. The plan check binds the values, but the product suite alone would not catch a drifted shown.json. (2) browser_walk.mjs:27 leaves its e2e-workbooks-saved-* temp dir behind on every run. -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r0-b2` | b2 | `tests/e2e/workbooks/checks/a_r0_b2_browser.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | three realistic workbooks compute as Calc does through the CLI | `tests/e2e/workbooks/checks/a_r0_b1_cli.sh` — |
| not yet | b2 | the same workbooks open, display and save in the browser | no landed check |

## 5. Out of scope and risks

- **Out of scope:** changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:tests/e2e/workbooks/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-r0-spreadsheet-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-r0-spreadsheet-1` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-r0-spreadsheet-2` | `impl-a1@alebairos` |
| Reviewed `wi-a-r0-spreadsheet-2` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-r0-spreadsheet-1`:

- `tests/e2e/workbooks/test_cli.py` +95 −0 (test)
- `tests/e2e/workbooks/checks/a_r0_common.py` +80 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_browser.mjs` +74 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_cdp.mjs` +70 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_b2_browser.sh` +31 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_b1_cli.sh` +26 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_books.json` +15 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_calc.json` +15 −0 (plan check)
- `tests/e2e/workbooks/checks/a_r0_shown.json` +15 −0 (plan check)
- `tests/e2e/workbooks/books/budget.calc.json` +5 −0 (test)
- `tests/e2e/workbooks/books/budget.json` +5 −0 (test)
- `tests/e2e/workbooks/books/grades.calc.json` +4 −0 (test)
- `tests/e2e/workbooks/books/grades.json` +4 −0 (test)
- `tests/e2e/workbooks/books/orders.calc.json` +4 −0 (test)
- `tests/e2e/workbooks/books/orders.json` +4 −0 (test)
- `tests/e2e/workbooks/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #21](https://github.com/alebairos/sheet-exp-a/pull/21)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 29 h 05 min so far
- Loops: 0
- Waste: 0 min
- Size: 0 lines (+0 −0, 8 files, ≤400; tests 121 lines); plan check files laid over by land, not in the size: +326 −0, 8 files
