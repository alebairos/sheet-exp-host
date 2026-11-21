# Intent `a-v1-cell-edit`

## 1. Outcome

> In the browser, editing a formula inside its cell destroys it. Observed: A3 =A1+A2 showing 30, F2, End, type +1, Enter: the editor opens with 30 and A3 becomes the text "30+1"; F2 then Enter with no typing turns =0.1+0.2 into the constant 0.3, '007 into the number 7 and =1/0 into nothing; double-click never opens the editor. Expected, as in Calc: the in-cell editor shows what was typed (the formula), and opening and closing it unchanged changes nothing (G1, G2, G3; prior S12, scored T9 = 0). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: in work · 2 work items · 3 bullets

## 2. What you will see

In the app page, F2 or a double-click on a formula cell opens the editor in the cell with the formula as typed (=A1+A2, not 30). Edit it (End, +1, Enter) and the cell shows the new result (31); Save JSON keeps =A1+A2+1. Opening the editor on any cell and leaving with Enter or Escape without typing changes nothing: =1/0 stays #DIV/0!, =0.1+0.2 stays a formula, the text 007 stays text. Screens: evidence 0-today-*.png (now) against 1-F2-on-A3.png and 2-after-+1-Enter.png (prototype).

- [a-v1-cell-edit/README.md](https://github.com/alebairos/sheet-exp-host/blob/2abfc28ad7753a90f4045c0df8f3113ccfc27b8b/a-v1-cell-edit/README.md)
- [a-v1-cell-edit/0-today-F2-on-A3.png](https://github.com/alebairos/sheet-exp-host/blob/2abfc28ad7753a90f4045c0df8f3113ccfc27b8b/a-v1-cell-edit/0-today-F2-on-A3.png)
- [a-v1-cell-edit/0-today-after-+1-Enter.png](https://github.com/alebairos/sheet-exp-host/blob/2abfc28ad7753a90f4045c0df8f3113ccfc27b8b/a-v1-cell-edit/0-today-after-+1-Enter.png)
- [a-v1-cell-edit/1-F2-on-A3.png](https://github.com/alebairos/sheet-exp-host/blob/2abfc28ad7753a90f4045c0df8f3113ccfc27b8b/a-v1-cell-edit/1-F2-on-A3.png)
- [a-v1-cell-edit/2-after-+1-Enter.png](https://github.com/alebairos/sheet-exp-host/blob/2abfc28ad7753a90f4045c0df8f3113ccfc27b8b/a-v1-cell-edit/2-after-+1-Enter.png)
- [a-v1-cell-edit/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/2abfc28ad7753a90f4045c0df8f3113ccfc27b8b/a-v1-cell-edit/prototype.diff)

## 3. Approach

Cause, as read in the code and run on main. (1) web/io/index.html gives the grid the computed workbook, so the in-cell editor starts from the value (inputText(30)). Typing then edits the value, and the formula is lost (G1). (2) The page finds edits by diffing the grid's typed cells against the computed ones. So Enter on an untouched editor turns =0.1+0.2 into 0.3 (the value read back), turns '007 into 7 (the grid's parseInput), and deletes =1/0 (an error's input text is ""), all as fresh edits (G2). (3) Every click redraws the whole table, so a real double-click's second click lands on a new element and Chrome fires no dblclick (G3).
Fix (WI 1, about 30 lines in grid.js and index.html, as in the evidence prototype). mount() takes two options. textOf(ref) gives the editor's starting text; the page passes the formula bar's barText of the workbook as typed (formulas, '007 with its apostrophe). onEdit(ref, text) receives a commit only when the user changed that text: Enter or Escape on an untouched editor changes nothing and Enter still moves down. The page sends onEdit to controller.edit(ref, text), which a-i11's a11_b3 check reads for, then recomputes and redraws at the grid's current selection, and drops the computed-vs-typed diff. A click on the already selected cell does not redraw, so the double-click reaches the same td. Without the options the grid behaves as today, so a-i9's tests hold. WI 2 adds the product's own browser test, tests/e2e/ui/test_cell_edit.py, which ./test.sh runs. It may reuse a_r2_cdp.mjs and the checks' a_v1_ce_page.mjs helpers.

Beliefs:
- ran: on main, F2 on A3 (=A1+A2) opens the editor with 30, and End, +1, Enter stores the text 30+1. A real double-click (clickCount 1 then 2) opens no editor. Settled by a_v1_ce_b1_formula.sh and a_v1_ce_b2_unchanged.sh, both red on main (evidence 0-today-*.png).
- code: the editor's start text and the diff in index.html's onChange are the whole cause of G1/G2. ran: the prototype changes only those two, plus the click redraw, and b1 and b2 pass. Settled by b1 and b2.
- ran: the values come from LibreOffice Calc 26.8.1.1 headless (a_v1_ce_probe.py, read from a_v1_ce_calc.json): A3 30, then 31 for =A1+A2+1 and 50 for =A1+A2*2; C1 #DIV/0!, D1 0.3, D2 007, D3 TRUE, F1 3. Settled by b1 and b2.
- ran: on the prototype ./test.sh (75 tests), the a-i9 grid checks, the a-i10 bar checks, the a-i11 io checks (a11_b3 included, once edits go through controller.edit), the a-r2 walk-through and the a-r0 browser check all pass. Settled by the land test.
- ran: this desktop's Chromium opens an extension tab about 1 s after launch that hides the page, and bringing the page back blurs an open editor. The checks wait 1.5 s after Open and bring the page to the front once, before any input. memory: a CI runner has no such tab. Settled by b1 and b2 passing both here and in land.
- code: only text the user changed is committed, so editing other text in a cell still follows the grid's own typing rules (50% stays text: S23). Making the grid and the bar parse alike is another intent's job (a-v1-text-rules / a-v1-entry-display). Settled by: not claimed here.

Learned from RECORD.md and the overlapping pages: G1/S12 had been carried as 'by design' from a-i11 to a-r2. a-r2 rejected in-cell editing because 'changing that is changing the grid', and the review scored T9 = 0, so this plan changes the grid. a-i10 rejected importing grid.js into the bar, so the bar's rules reach the grid through the page (textOf), and neither part imports the other. a-i11's attempt 1 stacked listeners on each redraw, so the grid is still mounted once and redrawn through setState. a-i9 suggested mousedown selection as a follow-up. Here only the redraw on a click of the selected cell is skipped; clicking another cell while editing stays with a-v1-grid-keys. Checks drive the page as shipped with real input, not the grid alone, because parts tested alone failed together before. Overlapping intents: a-v1-big-sheets (planned, also changes mount() and the page's redraw: whichever lands second carries both), a-v1-grid-keys, a-v1-typing-kept, a-v1-sheet-tabs, a-v1-keep-work.

- **Reuses:** The formula bar's barText (the cell as typed, with Calc's apostrophe for number-like text), the io controller's edit(ref, text) and the compute path, and the grid's mount/setState/startEdit. Checks reuse a_r2_cdp.mjs (Node standard library DevTools pipe).
- **Removes:** The page's computed-vs-typed diff (changedRefs) as the way edits are found, and the full redraw on a click of the already selected cell.
- **Rejected:** Giving the grid the typed workbook instead of the computed one: it would then display formulas instead of values. Making the grid import formula_bar.js: a-i10 rejected coupling the two parts, so the page passes textOf. Committing an untouched editor's text anyway and comparing values: =0.1+0.2 and 0.3 compare equal but are not the same cell. Moving the grid to mousedown selection: that also changes click-while-editing, which is a-v1-grid-keys. Editing through the formula bar only: b3 asks for in-cell editing without the bar.

## 4. Work items

### `wi-a-v1-cell-edit-1`: In-cell editor edits what was typed

The grid's in-cell editor opens with the cell as typed (the formula, '007) and only commits text the user changed, through the controller, and a click on the selected cell no longer redraws, so F2 and double-click edit formulas instead of destroying them.

Status: attempt 2 in work by `impl-a2@alebairos`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ce-b1` | b1 | `tests/e2e/ui/checks/a_v1_ce_b1_formula.sh` | red | — |
| `ac-ce-b2` | b2 | `tests/e2e/ui/checks/a_v1_ce_b2_unchanged.sh` | red | — |

### `wi-a-v1-cell-edit-2`: Product browser test for in-cell editing

Adds tests/e2e/ui/test_cell_edit.py, run by ./test.sh in headless Chrome, which edits a formula in its cell with F2 and with a double-click and opens and closes the editor on every kind of cell without change, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-cell-edit-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ce-suite` | b1, b2, b3 | `tests/e2e/ui/checks/a_v1_ce_suite.sh` | red | — |
| `ac-ce-judge` | b3 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user fix an existing formula inside its cell end to end, without touching the formula bar: open a workbook, F2 or double-click the formula cell, see the formula, change it, press Enter, see the new result; and can they open and leave cells of every kind (formula, error, text like 007, number) without anything changing? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | F2 or double-click on a formula cell opens the editor with the formula as typed; editing it and pressing Enter stores the edited formula and the grid shows its new value | no landed check |
| not yet | b2 | opening the editor on any cell (formula, error, text such as '007, number) and pressing Enter or Escape without typing leaves the cell's content and value unchanged | no landed check |
| not yet | b3 | an ordinary user can, through the shipped page, edit an existing formula in its cell end to end (type, fix, see result) without using the formula bar | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the formula bar's own behaviour; multiple sheets
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-cell-edit-1` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-v1-cell-edit-1` | `rev-a@alebairos` |
| Implemented `wi-a-v1-cell-edit-2` | — |
| Reviewed `wi-a-v1-cell-edit-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 4 h 40 min so far
- Loops: 1 (D5 review 1)
- Waste: 18 min
- Size: nothing landed yet
