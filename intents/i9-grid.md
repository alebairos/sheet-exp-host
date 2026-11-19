# Intent `i9-grid`

## 1. Outcome

> In the browser I see a grid of cells, select one and edit its value

Kind: Feature · State: awaiting the verdict · 1 work item · 2 bullets

## 2. What you will see

In the browser, a spreadsheet grid: column letters A, B, C… across the top, row numbers down the side, each cell showing the computed value as Calc shows it (1 not 1.0, 0.3 not 0.30000000000000004, TRUE/FALSE, errors like #DIV/0! in red, numbers right-aligned). Click a cell to select it (blue outline); double-click, press Enter or just start typing to edit it; Enter commits, Escape cancels. A typed 42 becomes a number, TRUE a boolean, anything else text, and an emptied cell becomes blank. The prototype in the media is clickable: it is the screen you will get, with sample values.

- [i9-grid/prototype.html](https://github.com/alebairos/sheet-exp-host/blob/4741ef5810b847a273f5d9bc58e3e7e16ad05491/i9-grid/prototype.html)
- [i9-grid/grid.js](https://github.com/alebairos/sheet-exp-host/blob/4741ef5810b847a273f5d9bc58e3e7e16ad05491/i9-grid/grid.js)

## 3. Approach

The grid first, as one plain ES module, web/grid/grid.js, with no build step and no libraries, split so most of it is testable without a browser: display(value) formats a computed JSON value (15 significant digits, like Calc's general format); createState(book, sheet), select(state, ref) and edit(state, ref, text) are pure functions over the workbook JSON (typed text: a number if it reads as one, TRUE/FALSE in any case, "" removes the cell, anything else, including =formulas, is kept as text for later intents); renderHTML(state, {rows, cols}) returns the table with data-ref on every cell, class selected on the selected one and HTML-escaped text; mount(container, state, {rows, cols, onChange}) is the only DOM code: it draws renderHTML, selects on click, edits with an input on double-click, Enter, F2 or typing, and calls onChange with the new state so the formula bar (i10) and open/save (i11) plug in later. web/grid/index.html shows a sample workbook. The plan checks (tests/web/grid/checks) run the module under Node.js, already on the land runner image; unit tests may go in tests/web/grid.

- **Reuses:** The web/grid directory from i0-skeleton; SPEC.md's workbook JSON, the same shape ./engine reads and writes, as the grid's data.
- **Removes:** The placeholder web/grid/.gitkeep, replaced by the grid module and a short index page.
- **Rejected:** A framework (React, Vue) or a bundler: needs npm and a build in every clean clone and in land, for one table. A canvas-drawn grid: harder to test and to select text in, and not needed at this size. Testing through a headless browser: needs a browser install on the runner; the pure-function split lets Node test what matters, and mount stays small.

## 4. Work items

### `wi-i9-grid-1`: Browser cell grid

Add web/grid/grid.js so a workbook renders as a selectable, editable table in the browser, proven by the two plan checks under Node.

Status: landed (`caf47ed9691a`)

**The passing review noted:** > pass wi-i9-grid-1 (commit 633842e15cbd822047b24b93ccfa033775f158c4 on ancestry plan/i9-grid f0800a23)
> 
> ac-b1 (b1: the grid renders a workbook's computed values): PASS
> - reran tests/web/grid/checks/b1_render.sh on WI tree → exit 0 (ok b1)
> - display/formatNumber: web/grid/grid.js:29-50 (Calc general format, TRUE/FALSE, errors, blank)
> - createState/renderHTML: web/grid/grid.js:58-62,105-126 (headers, data-ref cells, HTML escape, selected/num/err classes)
> - index.html sample mount: web/grid/index.html:18-25
> 
> ac-b2 (b2: selecting and editing a cell updates it): PASS
> - reran tests/web/grid/checks/b2_edit.sh on WI tree → exit 0 (ok b2)
> - select: web/grid/grid.js:64-66; edit/parseInput: web/grid/grid.js:77-102 (number/TRUE/FALSE/text/blank delete)
> - mount wires click/dblclick/keydown: web/grid/grid.js:135-225 (exported; check asserts typeof mount === function)
> 
> suite: ./test.sh → all tests passed (exit 0)
> 
> scope: paths under exp-b:web/grid/** and exp-b:tests/web/grid/** only
> - note: WI ancestry includes plan commit f0800a23 adding tests/web/grid/checks/*.sh (contract). Belongs under tests/web/grid; law 9 drops check-file edits at land.
> - no path outside scope

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/web/grid/checks/b1_render.sh` | red | — |
| `ac-b2` | b2 | `tests/web/grid/checks/b2_edit.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | the grid renders a workbook's computed values | `tests/web/grid/checks/b1_render.sh` — |
| not yet | b2 | selecting and editing a cell updates it | `tests/web/grid/checks/b2_edit.sh` — |

## 5. Out of scope and risks

- **Out of scope:** formulas in the UI; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:web/grid/**`, `exp-b:tests/web/grid/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i9-grid-1` | `impl-2@alebairos` |
| Reviewed `wi-i9-grid-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-i9-grid-1`:

- `web/grid/grid.js` +226 −0
- `tests/web/grid/checks/b2_edit.sh` +38 −0 (plan check)
- `tests/web/grid/checks/b1_render.sh` +36 −0 (plan check)
- `web/grid/index.html` +26 −0
- `tests/web/grid/__init__.py` +1 −0 (plan check)
- `web/grid/.gitkeep` +0 −1

Landing pull request: [exp-b #3](https://github.com/alebairos/sheet-exp-b/pull/3)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 10 h 08 min so far
- Loops: 0
- Waste: 0 min
- Size: 253 lines (+252 −1, 3 files, ≤400; tests 0 lines); plan check files laid over by land, not in the size: +75 −0, 3 files
