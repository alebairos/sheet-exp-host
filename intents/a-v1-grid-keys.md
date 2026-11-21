# Intent `a-v1-grid-keys`

## 1. Outcome

> Moving around the browser grid loses my place or my text. Observed: Tab on A1 leaves the selection on A1 and moves focus to BODY; typing 77 then Tab commits but stays; clicking another cell while editing commits but leaves the old cell selected; text typed in the formula bar is silently dropped when you click away (G7, G8, G9; prior S13). Expected, as in Calc: Tab commits and moves right, Shift+Tab left; a click while editing commits and selects the clicked cell; leaving the bar commits what was typed. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: accepted · 2 work items · 3 bullets

## 2. What you will see

Moving around the grid works like Calc. Tab commits what you typed and moves right, Shift+Tab moves left, and the keyboard stays in the grid. Clicking another cell while typing in one keeps what you typed and selects the cell you clicked. Text typed in the formula bar is kept when you click a cell instead of pressing Enter. Nothing else about editing changes.

- [a-v1-grid-keys/README.md](https://github.com/alebairos/sheet-exp-host/blob/22ccf802141d5d35897c0fe4316f5adefa05a03f/a-v1-grid-keys/README.md)
- [a-v1-grid-keys/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/22ccf802141d5d35897c0fe4316f5adefa05a03f/a-v1-grid-keys/prototype.diff)

## 3. Approach

Cause, as read in the code and run on main. (1) The grid's key handler has no Tab case, so the browser moves focus out of the grid. (2) The grid selects on click, but a click while editing first blurs the editor; the blur commits, and that redraws the table (innerHTML) under the pointer, so the click lands on a removed element and nothing is selected (a-i9's known follow-up). (3) The formula bar commits only on Enter. When a grid cell is clicked, the grid's selection change redraws the bar before its input loses focus, so the typed text is dropped.
Fix (WI 1, about 40 lines, as in the evidence prototype). grid.js: Tab / Shift+Tab move right/left, with or without an open edit (an open edit commits first), and keep focus in the grid. Selection moves to mousedown; with an edit open, mousedown commits it and selects the pressed cell in one update, so nothing is redrawn under the click. formula_bar.js: pending text (changed from what the bar showed) is committed when the bar is redrawn for another cell or loses focus, through the same commit/onCommit path as Enter; unchanged text commits nothing. index.html: after a recompute, redraw at the grid's current selection (grid.state.selected), not at the cell that was committed, so the user's click wins. WI 2 adds tests/e2e/ui/test_grid_keys.py.

Beliefs:
- ran: on main, Tab on A1 leaves A1 selected and focus leaves the grid; typing 5 in E1 then clicking E3 leaves E1 selected; =1+1 typed in the bar for E5 is lost when F6 is clicked. Settled by a_v1_gk_b1_tab.sh, a_v1_gk_b2_click.sh and a_v1_gk_b3_bar.sh, all red on main.
- ran: the prototype (evidence prototype.diff) passes all three, and ./test.sh and every a-i9/a-i10/a-i11/a-r0/a-r2 check still pass. My first prototype committed the bar only on blur and failed b3, because the grid's mousedown redraws the bar before the blur. Committing on the redraw for another cell fixed it. Settled by b3.
- human: Calc's behaviour (Tab moves right and Shift+Tab left, a click while editing commits and selects, leaving the input line by a click keeps the edit) is from the outcome as parked. These are UI behaviours with no computed values, so no reference run applies. Settled by SpecAccept and the judge check.
- code: selecting on mousedown changes when the selection moves (on press, as in Calc, not on release). a-r2's walkthrough and a-r0's browser check click cells and still pass on the prototype. Settled by the land test.

Learned from RECORD.md and the overlapping pages: a-i9 recorded 'clicking another cell commits and redraws before the click lands' and suggested mousedown selection, which a-i10 could have taken up and nobody parked. This plan takes it. a-i11's attempt 1 stacked listeners per redraw, so the grid is still mounted once and handlers are swapped, not added. The checks use real keys and clicks on the shipped page, because the grid and the bar were tested apart before and failed together (S13/S14). Overlaps: a-v1-cell-edit (also changes the click handler to keep double-click working, and its in-cell editor's start text), a-v1-big-sheets (also keeps the selection after a recompute) and a-v1-typing-kept (keeps an open editor across a recompute) all touch grid.js and index.html. The same index.html line (show at the current selection) is in a-v1-big-sheets' plan, and whichever lands first carries it.

- **Reuses:** The grid's move/select/edit/update and its single mount, the formula bar's commit and onCommit path, and the page's busy queue and show().
- **Removes:** The grid's click-based selection (replaced by mousedown), and Enter as the only way the formula bar commits.
- **Rejected:** Keeping click selection and delaying the blur commit with a timer: it races with the click, and the review saw such intermittent loss (S14). Committing the bar only on blur: the prototype showed the grid redraws the bar first, so the text was still lost. Moving the bar's commit into the page: the bar owns its text, and the page would need to read a half-typed input. Undo: out of scope (a-v1-keep-work).

## 4. Work items

### `wi-a-v1-grid-keys-1`: Tab, click-to-commit and bar commit on leave

The grid handles Tab and Shift+Tab (commit, move, keep focus) and selects on mousedown so a click while editing commits and selects the clicked cell; the formula bar commits typed text when the user clicks away; the page redraws at the current selection.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-gk-b1` | b1 | `tests/e2e/ui/checks/a_v1_gk_b1_tab.sh` | red | — |
| `ac-gk-b2` | b2 | `tests/e2e/ui/checks/a_v1_gk_b2_click.sh` | red | — |
| `ac-gk-b3` | b3 | `tests/e2e/ui/checks/a_v1_gk_b3_bar.sh` | red | — |

### `wi-a-v1-grid-keys-2`: Product browser tests for grid keys

Adds tests/e2e/ui/test_grid_keys.py, run by ./test.sh in headless Chrome, covering Tab/Shift+Tab, a click while editing and leaving the formula bar by a click, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-grid-keys-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-gk-suite` | b1, b2, b3 | `tests/e2e/ui/checks/a_v1_gk_suite.sh` | red | — |
| `ac-gk-judge` | b1, b2, b3 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user fill in a small table quickly, typing a value and pressing Tab to go right, Shift+Tab to go back, clicking around while typing, and typing in the formula bar then clicking a cell, without ever losing what they typed or their place? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | Tab commits any open edit and selects the cell to the right, Shift+Tab the cell to the left, and keyboard focus stays in the grid | no landed check |
| not yet | b2 | clicking another cell while editing commits the edit and selects the clicked cell | no landed check |
| not yet | b3 | text typed in the formula bar is committed, not dropped, when the user clicks a cell of the grid | no landed check |

## 5. Out of scope and risks

- **Out of scope:** undo
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/formula_bar/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/formula_bar/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-grid-keys-1` | — |
| Reviewed `wi-a-v1-grid-keys-1` | — |
| Implemented `wi-a-v1-grid-keys-2` | — |
| Reviewed `wi-a-v1-grid-keys-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 11 h 01 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
