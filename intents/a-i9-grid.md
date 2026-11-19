# Intent `a-i9-grid`

## 1. Outcome

> In the browser I see a grid of cells, select one and edit its value

Kind: Feature · State: Met · 1 work item · 2 bullets

## 2. What you will see

In the browser, a spreadsheet grid: column letters A, B, C… across the top, row numbers down the side, each cell showing the computed value as Calc shows it (1 not 1.0, 0.3 not 0.30000000000000004, TRUE/FALSE, errors like #DIV/0! in red, numbers right-aligned). Click a cell to select it (blue outline); double-click, press Enter or just start typing to edit it; Enter commits, Escape cancels. A typed 42 becomes a number, TRUE a boolean, anything else text, and an emptied cell becomes blank. The prototype in the media is clickable: it is the screen you will get, with sample values.

- [a-i9-grid/prototype.html](https://github.com/alebairos/sheet-exp-host/blob/8142fb3b706d43a2e4aa6a0c8e926e8e5c1ccfcb/a-i9-grid/prototype.html)
- [a-i9-grid/grid.js](https://github.com/alebairos/sheet-exp-host/blob/8142fb3b706d43a2e4aa6a0c8e926e8e5c1ccfcb/a-i9-grid/grid.js)

## 3. Approach

The grid first, as one plain ES module, web/grid/grid.js, with no build step and no libraries, split so most of it is testable without a browser: display(value) formats a computed JSON value (15 significant digits, like Calc's general format); createState(book, sheet), select(state, ref) and edit(state, ref, text) are pure functions over the workbook JSON (typed text: a number if it reads as one, TRUE/FALSE in any case, "" removes the cell, anything else, including =formulas, is kept as text for later intents); renderHTML(state, {rows, cols}) returns the table with data-ref on every cell, class selected on the selected one and HTML-escaped text; mount(container, state, {rows, cols, onChange}) is the only DOM code: it draws renderHTML, selects on click, edits with an input on double-click, Enter, F2 or typing, and calls onChange with the new state so the formula bar (a-i10) and open/save (a-i11) plug in later. web/grid/index.html shows a sample workbook. The plan checks (tests/web/grid/checks) run the module under Node.js, already on the land runner image; unit tests may go in tests/web/grid.

- **Reuses:** The web/grid directory from a-i0-skeleton; SPEC.md's workbook JSON, the same shape ./engine reads and writes, as the grid's data.
- **Removes:** The placeholder web/grid/README.md content, replaced by a short note on the module's API.
- **Rejected:** A framework (React, Vue) or a bundler: needs npm and a build in every clean clone and in land, for one table. A canvas-drawn grid: harder to test and to select text in, and not needed at this size. Testing through a headless browser: needs a browser install on the runner; the pure-function split lets Node test what matters, and mount stays small.

## 4. Work items

### `wi-a-i9-grid-1`: Browser grid: show, select, edit

Add web/grid: a dependency-free JavaScript module and page that draws a sheet's computed values as a lettered and numbered grid, highlights the selected cell and lets you type a new value into it, so the UI has its central surface.

Status: landed (`381bc461484c`)

**The passing review noted:** > PASS. Verify rerun in a worktree of 7ca9aea (node v26): both checks green (ok b1, ok b2); on plan base 8770f27 both red (grid.js missing). ./test.sh OK. No check file edited; all 5 paths inside web/grid and tests/web/grid.
> ac-a9-b1 (tests/web/grid/checks/a9_b1_render.sh): renderHTML web/grid/grid.js:105-126 (column letters via colName :8-14, row numbers, data-ref on every td, class selected/num/err, HTML-escaped text :52-53); display/formatNumber :30-50 (15 significant digits, 1E+15 / 1E-05, booleans TRUE/FALSE, error code text), styled in web/grid/grid.css (num right, err red, selected blue outline).
> ac-a9-b2 (tests/web/grid/checks/a9_b2_edit.sh): createState/select/move :58-72, parseInput :74-86 (number, TRUE/FALSE any case, "" -> blank, anything else incl. =formulas as text, as designed), edit :95-102 (pure, copies book/sheet, deletes on blank); mount :135-226 wires click select, dblclick/Enter/F2/typing edit, Enter commit + move down, Escape cancel, blur commit, arrows, Delete clears, onChange on every change.
> Notes, not blocking: (1) tests/web/grid/grid.test.mjs (7 tests, all pass under node --test) is not run by ./test.sh, which only discovers Python unittest, so land never runs it; registering it is outside this intent's scope (scripts/test) — worth a follow-up. (2) While editing, clicking another cell commits on blur and redraws the table before the click lands, so the clicked cell may not get selected in some browsers (mount :177-185); a later UI intent may want mousedown-based selection. (3) Only mount is untested by the checks (no DOM in Node), as the design says. -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a9-b1` | b1 | `tests/web/grid/checks/a9_b1_render.sh` | red | pass |
| `ac-a9-b2` | b2 | `tests/web/grid/checks/a9_b2_edit.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | the grid renders a workbook's computed values | `tests/web/grid/checks/a9_b1_render.sh` pass |
| PASS | b2 | selecting and editing a cell updates it | `tests/web/grid/checks/a9_b2_edit.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** formulas in the UI; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:web/grid/**`, `exp-a:tests/web/grid/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i9-grid-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-i9-grid-1` | `rev-a@alebairos` (passed attempt 1) |
| Verdict (Met) | `alebairos` |

Product checks:

- `tests/web/grid/checks/a9_b1_render.sh`: pass
- `tests/web/grid/checks/a9_b2_edit.sh`: pass

Outcome report:

- **Built:** The browser grid in exp-a web/grid (landed via exp-a PR #5, one work item, first attempt, review passed). Serve the repo with python3 -m http.server and open /web/grid/. It shows lettered columns and numbered rows. Values display as Calc shows them: 0.30000000000000004 shows as 0.3, numbers are right-aligned, TRUE/FALSE appear as words and #DIV/0! is red. Click selects a cell (blue outline). Double-click, Enter, F2 or typing edits it; Enter commits and moves down, Escape cancels, arrows move and Delete clears. A typed 42 is stored as a number, TRUE as a boolean, empty input as a blank cell, and anything else, including =formulas, as text for now. It matches the plan's prototype, plus arrows and Delete. It is plain JavaScript with no libraries or build step. built/grid.png is the landed page, rendered headless from exp-a main 43e422a.
- **Advice:** Adopt, with three follow-ups from the review. (1) The grid's own unit tests (tests/web/grid/grid.test.mjs, run by Node) are not run by ./test.sh, so land never runs them. Park a small intent to register them in the shared test script. (2) While editing, clicking another cell commits and redraws before the click lands, so the clicked cell may not get selected. Watch for it when trying it by hand; the formula-bar intent (a-i10) can switch to mousedown selection. (3) Formulas are shown as typed text until the evaluator and formula bar are wired in (a-i3, a-i10).
- [a-i9-grid/built/grid.png](https://github.com/alebairos/sheet-exp-host/blob/735020604e1888de711141c48c3113691af6483f/a-i9-grid/built/grid.png)
- [a-i9-grid/built/index.html](https://github.com/alebairos/sheet-exp-host/blob/735020604e1888de711141c48c3113691af6483f/a-i9-grid/built/index.html)
- [a-i9-grid/built/grid.js](https://github.com/alebairos/sheet-exp-host/blob/735020604e1888de711141c48c3113691af6483f/a-i9-grid/built/grid.js)
- [a-i9-grid/built/grid.css](https://github.com/alebairos/sheet-exp-host/blob/735020604e1888de711141c48c3113691af6483f/a-i9-grid/built/grid.css)

Files landed by `wi-a-i9-grid-1`:

- `web/grid/grid.js` +226 −0
- `tests/web/grid/grid.test.mjs` +61 −0 (test)
- `tests/web/grid/checks/a9_b2_edit.sh` +38 −0 (plan check)
- `tests/web/grid/checks/a9_b1_render.sh` +36 −0 (plan check)
- `web/grid/index.html` +18 −0
- `web/grid/README.md` +15 −1
- `web/grid/grid.css` +9 −0

Landing pull request: [exp-a #5](https://github.com/alebairos/sheet-exp-a/pull/5)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 8 h 29 min
- Loops: 0
- Waste: 0 min
- Size: 269 lines (+268 −1, 5 files, ≤400; tests 61 lines); plan check files laid over by land, not in the size: +74 −0, 2 files
