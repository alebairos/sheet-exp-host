# Intent `a-v1-sheet-tabs`

## 1. Outcome

> I can reach and edit every sheet of a workbook in the browser. Observed: opening order.json (sheets Prices and Order) shows only Prices with no tabs or selector, and typing 5 in B1 changes Prices!B1; Order!B1 can't be changed, so the CLI then prints 61.83, not 72.63 (G6; prior S20, T12 = 0). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Feature · State: accepted · 2 work items · 2 bullets

## 2. What you will see

Every sheet of a workbook is reachable in the browser. Under the grid, one tab per sheet (e.g. Prices | Order); click a tab and the grid shows that sheet, with its name shown before the formula bar's cell name. Edit a cell on the second sheet and only that sheet changes. Formulas on every sheet that read it update (Order total 34 to 65.5, Prices' ordered count 6 to 9, as in Calc), and Save JSON writes the change on the right sheet. Screen: evidence 1-order-tab.png.

- [a-v1-sheet-tabs/README.md](https://github.com/alebairos/sheet-exp-host/blob/db71dfb67bef9d2eee3784999bcdf6a967534ea7/a-v1-sheet-tabs/README.md)
- [a-v1-sheet-tabs/1-order-tab.png](https://github.com/alebairos/sheet-exp-host/blob/db71dfb67bef9d2eee3784999bcdf6a967534ea7/a-v1-sheet-tabs/1-order-tab.png)
- [a-v1-sheet-tabs/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/db71dfb67bef9d2eee3784999bcdf6a967534ea7/a-v1-sheet-tabs/prototype.diff)

## 3. Approach

Most value first: reaching the other sheets at all. The controller already keeps state.sheet and edits only that sheet (controller.edit). The grid and the bar already take the sheet from show(), and Save JSON already writes the whole workbook. So the change is the page: web/io/index.html gets a tab strip (#sheet-tabs, one role=tab button per sheet in the workbook's order, aria-selected on the current one) under the grid, and a #sheet-name label before the formula bar. A tab click (queued on the same busy chain as edits) sets controller.state.sheet and redraws at A1. Recomputation is already whole-workbook through /compute, so formulas on every sheet that read the edited one update. About 20 lines plus CSS (the evidence prototype is +21 -1). WI 2 adds tests/e2e/ui/test_sheet_tabs.py.

Beliefs:
- ran: on main the page has no tabs and no way to reach a second sheet, so both checks stop at 'the page has no sheet tab Order'. Settled by a_v1_st_b1_tabs.sh and a_v1_st_b2_edit.sh, both red on main.
- ran: LibreOffice Calc 26.8.1.1 (a_v1_st_probe.py, read from a_v1_st_calc.json) gives Order!B3 34 and Prices!D1 6 for the workbook as opened, and 65.5 and 9 after Order!B1 := 5. Settled by b1 and b2.
- ran: the prototype passes both checks, and ./test.sh plus the a-i11, a-r0 and a-r2 checks still pass. A tab click needs no grid change, since mount's setState takes the new sheet's state. Settled by the land test.
- code: the formula bar's own code (web/formula_bar) is outside this scope, so the sheet is named by #sheet-name next to it, which the bullet's 'the formula bar naming the sheet' is checked against. Settled by b1 and SpecAccept.
- code: Save CSV writes the current sheet (io.js toCSV(computed, state.sheet)), so it follows the selected tab. Settled by: not claimed by a check (CSV is one sheet by design, a-i11).

Learned from RECORD.md and the overlapping pages: a-r0 rejected sheet tabs as out of its scope and ordered its workbooks so the first sheet read the others, and the review then scored T12 = 0 (S20, G6). This is the separate intent a-r0 named. The checks go through the shipped page with real clicks and use Calc's values for the cross-sheet formulas. a-i11's lesson (mount the grid once, redraw through setState) is kept: tabs only change the state shown. Overlaps in web/io/index.html: a-v1-big-sheets, a-v1-cell-edit, a-v1-grid-keys, a-v1-keep-work and a-v1-error-help. Tabs add elements and one function and touch none of their lines except show(), where drawTabs() is one call.

- **Reuses:** The controller's state.sheet and edit(), the page's busy queue and show(), the grid's setState and the formula bar's sheet argument, and /compute's whole-workbook recalculation.
- **Removes:** none
- **Rejected:** A <select> of sheet names: tabs are what spreadsheet users look for (Calc, Excel), and a select hides the other sheets. Rendering every sheet stacked on one page: it does not scale and breaks the grid's single mount. Adding, renaming or deleting sheets: out of scope.

## 4. Work items

### `wi-a-v1-sheet-tabs-1`: Sheet tabs on the page

The page shows one tab per sheet under the grid and the active sheet's name before the formula bar. A tab click shows that sheet, so cells on every sheet can be seen and edited, with edits recomputing the whole workbook and saved on their own sheet.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-st-b1` | b1 | `tests/e2e/ui/checks/a_v1_st_b1_tabs.sh` | red | — |
| `ac-st-b2` | b2 | `tests/e2e/ui/checks/a_v1_st_b2_edit.sh` | red | — |

### `wi-a-v1-sheet-tabs-2`: Product browser tests for sheet tabs

Adds tests/e2e/ui/test_sheet_tabs.py, run by ./test.sh in headless Chrome, covering the tabs, switching sheets and an edit on the second sheet, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-sheet-tabs-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-st-suite` | b1, b2 | `tests/e2e/ui/checks/a_v1_st_suite.sh` | red | — |
| `ac-st-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user open a workbook with several sheets (say a price list and an order that reads it), find and switch between the sheets, change a quantity on the second sheet, see the totals on both sheets update, and save the change where it belongs? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | the page shows one tab per sheet of the open workbook and clicking a tab shows that sheet in the grid, with the formula bar naming the sheet | no landed check |
| not yet | b2 | editing a cell on the second sheet changes that sheet only, recomputes formulas on every sheet that read it, and Save JSON writes the edit on the right sheet | no landed check |

## 5. Out of scope and risks

- **Out of scope:** adding, renaming or deleting sheets
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/io/**`, `exp-a:web/grid/**`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-sheet-tabs-1` | — |
| Reviewed `wi-a-v1-sheet-tabs-1` | — |
| Implemented `wi-a-v1-sheet-tabs-2` | — |
| Reviewed `wi-a-v1-sheet-tabs-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 2 h 51 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
