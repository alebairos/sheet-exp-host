# Intent `a-v1-big-sheets`

## 1. Outcome

> I can see and edit every row and column of a large workbook in the browser. Observed: the grid always shows rows 1-20 and columns A-H; opening a 2001-row bank CSV, scrolling and ArrowDown/PageDown from A20 do nothing, so rows 21-2001 can't be seen or edited, though the data is intact (G5; prior S17, T11). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Feature · State: awaiting the verdict · 2 work items · 2 bullets

## 2. What you will see

On the app page (python3 web/io/serve.py, then /io/index.html) the grid fills the window and scrolls like Calc. Open a 2001-row, 12-column bank CSV, and the mouse wheel or scroll bars reach row 2001 and column L, with the row numbers and column letters staying in view. ArrowDown past the bottom edge and ArrowRight past column H keep going, and the view follows. PageDown/PageUp jump a screen at a time. Type into B2001 and press Enter: formulas that read it, such as a SUM at the top or a cell beside it, recompute, and the selection stays where you moved it. Scrolling stays smooth: each scroll step is under 100 ms in headless Chrome. Screens: 0-today-opened.png (today, 20 x 8 and stuck) and 1-opened.png / 2-scrolled-to-L2001.png (the prototype).

- [a-v1-big-sheets/README.md](https://github.com/alebairos/sheet-exp-host/blob/241304534254ad2452d7d1b58aa01a26bfa2b4a3/a-v1-big-sheets/README.md)
- [a-v1-big-sheets/0-today-opened.png](https://github.com/alebairos/sheet-exp-host/blob/241304534254ad2452d7d1b58aa01a26bfa2b4a3/a-v1-big-sheets/0-today-opened.png)
- [a-v1-big-sheets/1-opened.png](https://github.com/alebairos/sheet-exp-host/blob/241304534254ad2452d7d1b58aa01a26bfa2b4a3/a-v1-big-sheets/1-opened.png)
- [a-v1-big-sheets/2-scrolled-to-L2001.png](https://github.com/alebairos/sheet-exp-host/blob/241304534254ad2452d7d1b58aa01a26bfa2b4a3/a-v1-big-sheets/2-scrolled-to-L2001.png)
- [a-v1-big-sheets/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/241304534254ad2452d7d1b58aa01a26bfa2b4a3/a-v1-big-sheets/prototype.diff)

## 3. Approach

Most value first: the grid becomes a scroll box over the whole sheet. web/grid/grid.js draws only the rows and columns in view (about 35 x 13 at 1200x900) inside a box whose scroll size is the sheet's extent (its used cells and the selection, plus a margin, never under 20 x 8), with the header row and column sticky. A scroll redraws the window. The arrows no longer stop at row 20 or column H. PageDown/PageUp move one screen and scroll with it. Any move scrolls the selected cell into view. grid.css gives fixed row and column sizes so the window maths is exact, and web/io/index.html gives #grid the window's height. One page fix: after a recompute the page redraws at the selection the user has now, not the one taken at edit time. Without it, moving away while a big sheet recomputes jumps back to the edited cell. Keep renderHTML(state, {rows, cols}) and mount(container, state, {rows, cols, onChange}) working as they do (new options default to the top-left), so a-i9's tests and the a-r0/a-r2 browser checks still pass. Then WI 2: the product's own browser test, tests/e2e/ui/test_big_sheets.py, which ./test.sh discovers. It may drive Chrome with a_r2_cdp.mjs and the checks' a_v1_bs_page.mjs helpers (timedStep, seen).

Beliefs:
- ran: on main the page draws 20 rows x 8 columns, ArrowDown stops at A20 and the wheel scrolls nothing. Settled by a_v1_bs_b1_scroll.sh and a_v1_bs_b2_keys.sh, both red on main.
- ran: drawing only the visible window keeps a scroll step fast. On the prototype (evidence prototype.diff) each wheel step to the next paint took a median of 49 ms and at most 58 ms in headless Chromium 156. Settled by the b1 check's 100 ms bound on every step.
- ran: after an edit, the recompute's redraw puts the selection back under the edited cell (index.html show(s.selected) uses the selection from edit time). On a 2001-row sheet the user is thrown back. The prototype's show(grid.state.selected) fixes it. Settled by b2's "M2001 stays selected" step.
- ran: the expected values come from LibreOffice Calc 26.8.1.1, run headless on the same CSV: L2001 200111; M1 =SUM(B2:B2001) 200302000, then 200101904 after B2001 := 5; M2001 =B2001*2 400202, then 10. a_v1_bs_probe.py wrote a_v1_bs_calc.json and the checks read it. Settled by b2.
- ran: on this desktop, Chromium opens a policy extension's tab that hides the test page, and a hidden page draws no frames (CDP wheel steps then hang). The checks bring the page to the front and do not time a step during which it was hidden (timedStep). Settled by b1 passing here.
- memory: a CI runner's Chrome has no such tab, so timedStep is a no-op there. Settled by the land test run.
- code: the a-i9 grid tests and the a_r0 browser check read only the first screen (A1:H20). ran: on the prototype ./test.sh (75 tests), a9_b1_render.sh, a9_b2_edit.sh, a_r2_b1_walkthrough.sh and a_r0_b2_browser.sh all pass. Settled by the land test.

Learned from RECORD.md and the overlapping pages: S17/G5 is this outcome, and the record notes that no intent ever named grid size or scrolling (a-r0 checked only A1:H20), so the checks name it. Parts were tested in isolation and failed together (a-i9/a-i10/a-i11), so every check here drives the served page with real keys and wheel events through the product as shipped, and a judge check asks for the end-to-end task. Values come from running Calc, not memory. a-i11's grid is mounted once, and redraws go through setState (the attempt-1 listener stacking), which this plan keeps. The overlapping intents wait on this scope: a-v1-cell-edit (in-cell formulas), a-v1-grid-keys (Tab, click while editing), a-v1-typing-kept (an open editor during recompute), a-v1-sheet-tabs and a-v1-keep-work. Their behaviour is not changed here. Only the selection after a recompute is kept, because b2 needs it.

- **Reuses:** The grid's renderHTML/mount/move/select/edit and its display rules; web/io's controller, serve.py and POST /compute; the formula bar as is; the a-r2 DevTools helper tests/e2e/ui/checks/a_r2_cdp.mjs (Node standard library, no npm).
- **Removes:** The fixed 20 x 8 limit in the grid (the `inside()` guard that stops the arrows at the edge). Nothing else.
- **Rejected:** Drawing all 24,000 cells as one big table and letting the page scroll: every click and keypress redraws the whole table with innerHTML, which is far over 100 ms at this size. A canvas grid: a-i9 rejected it as hard to test, and every check and the formula bar read td[data-ref]. Paging buttons (rows 1-20, 21-40, ...): not how a spreadsheet moves, and b2 asks for the arrows and PageDown. Real CDP mouseWheel without bringing the page to the front: on this machine an extension tab hides the page and the steps hang, so it does not measure the product. Freezing panes, column resizing and sheet tabs: out of scope (a-v1-sheet-tabs has its own intent). Keeping an open editor alive across a recompute: that is a-v1-typing-kept.

## 4. Work items

### `wi-a-v1-big-sheets-1`: Scrolling grid over the whole sheet

The grid draws only the rows and columns in view inside a scroll box the size of the sheet, the arrows and PageDown/PageUp move past the old 20 x 8 edge with the view following, and the page keeps the user's selection when a recompute returns, so every row and column of a big CSV can be seen and edited.

Status: landed (`11fa25c61ed9`)

**The passing review noted:** > PASS. Reviewed commit 1c3ef7a (wi/wi-a-v1-big-sheets-1) against plan b9932e3 (base 5ed792b). Diff: web/grid/{grid.js,grid.css,README.md}, web/io/index.html, all inside the path scope.
> Verify, rerun (CHROME=/usr/bin/chromium, Linux):
> - ac-bs-b1 tests/e2e/ui/checks/a_v1_bs_b1_scroll.sh: WI ok (217 wheel steps to L2001 and back, median 49.2 ms, slowest 62.0 ms < 100 ms NFR); base FAIL ("after 400 wheel steps ... A2001 is still not visible").
> - ac-bs-b2 tests/e2e/ui/checks/a_v1_bs_b2_keys.sh: WI ok (A2001, M2001 reached, view follows; B2001:=5 gives M2001 10, M1 200101904 as in Calc); base FAIL ("ArrowDown selects A21 ... shows A20").
> - ./test.sh: Ran 75 tests OK (5.2 s). node --test tests/web/grid: 7/7. The earlier checks still pass on the WI: a9_b1/b2, a10_b1/b2, a11_b1/b2/b3, a_r0_b1/b2, a_r2_b1.
> Per AC:
> - b1: grid.js:156-232 makes the container a scroll box sized by extent() (grid.js:108-115), draws only the window (renderHTML top/left, grid.js:121-141) and redraws it on scroll (onScroll grid.js:225-232); grid.css sticky table with fixed 22/88 px cells.
> - b2: onKey (grid.js:271-283) removes the old inside() edge for the arrows; PageDown/PageUp move a screen; follow() (grid.js:197-208) scrolls the selection into view. The Enter commit no longer stops at row 20. index.html:91 redraws at grid.state.selected after a recompute, so the user is not thrown back to the edited cell.
> Extra probes (real Chromium, page as served):
> - A 2001-row bank-like CSV with long text in column B: rows still draw at 22 px; the bottom-right reaches L2001; 40x ArrowDown and 3x PageDown keep the selection visible.
> - Scrolled to row 1501: a real mouse click selects C1505; double-click, typing 77 and Enter commits 77, selects C1506 and does not jump the scroll.
> Notes (non-blocking):
> - With the desktop google-chrome first on PATH (no $CHROME), b1 hung for over 300 s on this machine while chromium passes. That is the environment issue the plan notes (an extension tab hides the page), not the code, but the check has no overall timeout; a runner whose browser hangs would stall instead of failing.
> - While an editor is open, scrolling does not redraw (onScroll skips while editing), so the row headers lag until commit. This is acceptable here; in-cell editing belongs to a-v1-cell-edit.
> - extent() grows the scroll space with the selection (+10 rows), so ArrowDown keeps going past the data, as in Calc.
> Usefulness only (not fidelity): an ordinary user can now reach and edit every row and column of a 2001-row sheet. The Calc values in the checks come from a_v1_bs_calc.json (LibreOffice run), not hand-written.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-bs-b1` | b1 | `tests/e2e/ui/checks/a_v1_bs_b1_scroll.sh` | red | pass |
| `ac-bs-b2` | b2 | `tests/e2e/ui/checks/a_v1_bs_b2_keys.sh` | red | pass |

### `wi-a-v1-big-sheets-2`: Product browser test for big sheets

Adds tests/e2e/ui/test_big_sheets.py, run by ./test.sh in headless Chrome, which opens a 2001-row CSV, scrolls to its last cell, moves with the arrows and PageDown/PageUp and edits row 2001, so the product keeps this behaviour.

Status: landed (`7db2dd26f2a0`) · depends on `wi-a-v1-big-sheets-1`

**The passing review noted:** > PASS. Reviewed attempt 4 (b488404, on attempt 3 4ea210b, base main 2070717) with the plan's checks (b9932e3). Runs used CHROME=/usr/bin/chromium.
> 
> - What changed: land attempt 3 failed on CI ("the column header L is in view ... false"). web/grid/grid.js:198-203 now wraps the drawn table in a sticky .grid-view the size of the scroll box, with overflow hidden (grid.css:14-15). The table is one row and one column larger than the box, and sticky positioning no longer pushes it back at the end of the scroll range. big_sheets.mjs:126-135 now asserts that the column headers sit at the box's top and the row headers at its left, at the bottom and right ends.
> - Scope: web/grid/grid.js and grid.css are in the intent's path scope (web/grid/**). This WI was planned as tests only, so I am flagging it as asked: the change belongs here. It fixes the shipped grid that the WI's own test exposed, and it is small (+8 -2).
> - Checks on the WI: ac-bs-suite gives "ok the product's big-sheet browser tests run and pass". WI-1's ac b1 gives "ok b1: scrolled to L2001 (200111) and back ... median 49.3 ms". ac b2 gives "ok b2: keys reach A2001 and M2001 ... M2001 10, M1 200101904 as in Calc". node --test tests/web/grid: 7/7. ./test.sh: 77 OK. big_sheets.mjs 3 times in a row: ok. close() is as I passed it on attempt 3.
> - The fix is real. I re-ran big_sheets.mjs under CDP Emulation.setDeviceMetricsOverride, with and without a 15px serif grid font injected, on the attempt-3 grid (old) and this attempt (wi). At 1200x900 (dpr 1), 1200x900 with the serif font, and 1013x701 (dpr 1.25), old fails "the column header L is in view" and wi passes the header steps. At 1500x1000 with serif and at 1280x760 (dpr 1.5), both pass.
> - Note (the test, not the product; same on old and wi): at narrow viewports (1013x701 dpr 1.25, 900x640 dpr 2) the test fails later with "M2001 recomputes to Calc's 10 ... shows null". After Enter in B2001 the view follows B2002, and with fewer than 12 columns visible M is not drawn. launch() fixes the window at 1200x900, so this is not a flake on CI. Reading M2001 after navigating back to it would make the test independent of the viewport.
> - Attribution note: this commit's author is "impl-a2@alebairos" with the human's e-mail address, not an implementer address. Attempts 1-3 used impl-a1@alebairos.invalid. The record noted the same on a-i7.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-bs-suite` | b1, b2 | `tests/e2e/ui/checks/a_v1_bs_suite.sh` | red | pass |
| `ac-bs-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user open a 2001-row, 12-column CSV such as a bank statement, scroll to the last row and to column L, move there and back with the arrow keys and PageDown/PageUp without losing their place, edit a cell in row 2001 and see the formulas that use it update, with scrolling that feels immediate? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | opening a CSV of 2001 rows and 12 columns, the user can scroll to and see row 2001 and column L | `tests/e2e/ui/checks/a_v1_bs_b1_scroll.sh` pass, `tests/e2e/ui/checks/a_v1_bs_suite.sh` pass, `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user open a 2001-row, 12-column CSV such as a bank statement, scroll to the last row and to column L, move there and back with the arrow keys and PageDown/PageUp without losing their place, edit a cell in row 2001 and see the formulas that use it update, with scrolling that feels immediate? Answer yes or no with what you tried.` fail |
| PASS | b2 | the arrow keys and PageDown/PageUp move the selection past the visible edge and the view follows it; editing a cell at row 2001 recomputes formulas that use it | `tests/e2e/ui/checks/a_v1_bs_b2_keys.sh` pass, `tests/e2e/ui/checks/a_v1_bs_suite.sh` pass, `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user open a 2001-row, 12-column CSV such as a bank statement, scroll to the last row and to column L, move there and back with the arrow keys and PageDown/PageUp without losing their place, edit a cell in row 2001 and see the formulas that use it update, with scrolling that feels immediate? Answer yes or no with what you tried.` fail |

## 5. Out of scope and risks

- **Out of scope:** sheet tabs; freezing panes, column resizing
- **Non-functional:** opening and scrolling a 2001-row sheet stays responsive (each scroll step under 100 ms in headless Chrome)
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-big-sheets-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-big-sheets-1` | `rev-a@alebairos` (passed attempt 1) |
| Implemented `wi-a-v1-big-sheets-2` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-v1-big-sheets-2` | `rev-a@alebairos` (passed attempt 4) |

Product checks:

- `tests/e2e/ui/checks/a_v1_bs_b1_scroll.sh`: pass
- `tests/e2e/ui/checks/a_v1_bs_b2_keys.sh`: pass
- `tests/e2e/ui/checks/a_v1_bs_suite.sh`: pass
- `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user open a 2001-row, 12-column CSV such as a bank statement, scroll to the last row and to column L, move there and back with the arrow keys and PageDown/PageUp without losing their place, edit a cell in row 2001 and see the formulas that use it update, with scrolling that feels immediate? Answer yes or no with what you tried.`: judged fail by `alebairos`: fail: I wasn't allowed to run anything: launching the served page in Chromium (the a_v1_bs_b1_scroll.sh and a_v1_bs_b2.mjs browser checks) was denied, and even git log on sheet-exp-a needed approval, so I couldn't open the 2001-row CSV, scroll to L2001, use the arrows or PageDown/PageUp, or edit B2001 myself. The rules say to fail rather than judge from code alone, and my earlier code-only passes (cli-input, eval-edges, number-text) went against that rule, so I'm not repeating them; the reviews' reports of passing runs don't count as my own run. | delegate: decided by the HITL's delegate (Claude, opus), per the HITL on 2026-11-19 07:05: "from now on until finishing the experiment, do it yourself". Signed as npub1p8lmv897hc9ew45cdjfqlurcgu5e3kg0mwkrptln4r7px4jzs5aqlhr9az.

Outcome report:

- **Built:** The browser grid now scrolls over the whole sheet instead of stopping at 20 rows x 8 columns. web/grid/grid.js draws only the rows and columns in view inside a scroll box the size of the sheet, and the row numbers and column letters stay in view. The arrows go past the old edge, PageDown/PageUp move a screen, and the view follows the selection. web/io/index.html now redraws at the user's current selection after a recompute, so moving away while a big sheet recomputes no longer jumps back. On the landed product (exp-a a2293fd), I ran all three checks in headless Chromium and all pass. A 2001-row, 12-column CSV scrolls to L2001 and back in 218 wheel steps (median 49 ms, slowest 61 ms, under the 100 ms bound). The keys reach A2001 and M2001. Setting B2001 to 5 recomputes M2001 to 10 and M1 to 200101904, as LibreOffice gives. ./test.sh passes with 124 tests, now including tests/e2e/ui/test_big_sheets.py. Where it left the plan: WI 2 was planned as tests only, but its own browser test failed on CI with column header L out of view at the end of the scroll range. Attempt 4 also fixed the shipped grid with a sticky view wrapper (+8 −2 in web/grid, inside the scope). That took 3 failed attempts and about 1 h 22 min of waste.
- **Advice:** The bullets show FAIL only because the usefulness judge was answered fail. Your delegate said it was not allowed to run the browser or git, so it saw nothing: 'I wasn't allowed to run anything'. That is not a finding about the product. The checks it would have needed pass on the landed product (evidence outcome.md). If you want Met, the judge needs answering again by someone who can run the page; otherwise PartiallyMet records that it was unjudged. Watch: (1) While a cell editor is open, scrolling does not redraw, so headers lag until commit (a-v1-cell-edit owns that). (2) The browser checks have no overall timeout, and with the desktop google-chrome first on PATH, b1 hung for over 300 s on this machine; chromium passes. (3) The WI-2 test reads M2001 without navigating to it, so it fails at narrow viewports (CI uses 1200x900, so it is stable there). (4) The WI-2 commit was authored with the human's e-mail under impl-a2, as on a-i7.
- [a-v1-big-sheets/outcome.md](https://github.com/alebairos/sheet-exp-host/blob/7a4a27105b03432da468c54f0b72e093493c51d0/a-v1-big-sheets/outcome.md)

Files landed by `wi-a-v1-big-sheets-1`:

- `web/grid/grid.js` +116 −20
- `tests/e2e/ui/checks/a_v1_bs_page.mjs` +98 −0 (plan check)
- `tests/e2e/ui/checks/a_v1_bs_b2.mjs` +65 −0 (plan check)
- `tests/e2e/ui/checks/a_v1_bs_probe.py` +42 −0 (plan check)
- `tests/e2e/ui/checks/a_v1_bs_suite.sh` +39 −0 (plan check)
- `tests/e2e/ui/checks/a_v1_bs_b1.mjs` +34 −0 (plan check)
- `tests/e2e/ui/checks/a_v1_bs_b2_keys.sh` +15 −0 (plan check)
- `web/grid/README.md` +10 −4
- `tests/e2e/ui/checks/a_v1_bs_b1_scroll.sh` +13 −0 (plan check)
- `web/io/index.html` +7 −5
- `web/grid/grid.css` +9 −0
- `tests/e2e/ui/checks/a_v1_bs_calc.json` +1 −0 (plan check)

Files landed by `wi-a-v1-big-sheets-2`:

- `tests/e2e/ui/big_sheets.mjs` +191 −0 (test)
- `tests/e2e/ui/test_big_sheets.py` +33 −0 (test)
- `tests/e2e/ui/browser.mjs` +26 −6 (test)
- `web/grid/grid.js` +6 −1
- `web/grid/grid.css` +2 −1
- `tests/e2e/ui/walkthrough.mjs` +1 −1 (test)

Landing pull request: [exp-a #30](https://github.com/alebairos/sheet-exp-a/pull/30)

## 7. The decision

**Verdict:a-v1-big-sheets**: A decision: show your human its options

- Met: `cooknship decide --answer Verdict:a-v1-big-sheets --option met`
- Partially met: unmet bullets park as follow-ups: `cooknship decide --answer Verdict:a-v1-big-sheets --option partially`
- Not met: every unmet bullet parks as a follow-up: `cooknship decide --answer Verdict:a-v1-big-sheets --option not_met`

## 8. Metrics

- Lead time: 4 h 19 min so far
- Loops: 3 (D4 build 1, D5 review 1, D6 landing 1)
- Waste: 1 h 22 min
- Size: 181 lines (+150 −31, 10 files, ≤400; tests 258 lines); plan check files laid over by land, not in the size: +307 −0, 8 files
