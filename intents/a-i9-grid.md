# Intent `a-i9-grid`

## 1. Outcome

> In the browser I see a grid of cells, select one and edit its value

Kind: Feature · State: in work · 1 work item · 2 bullets

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

Status: in review by `rev-a@alebairos`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a9-b1` | b1 | `tests/web/grid/checks/a9_b1_render.sh` | red | — |
| `ac-a9-b2` | b2 | `tests/web/grid/checks/a9_b2_edit.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | the grid renders a workbook's computed values | no landed check |
| not yet | b2 | selecting and editing a cell updates it | no landed check |

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
| Reviewed `wi-a-i9-grid-1` | `rev-a@alebairos` |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 8 h 03 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
