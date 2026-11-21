# Intent `a-v1-keep-work`

## 1. Outcome

> I don't lose work in the browser. Observed: Ctrl+Z does nothing; reloading the page empties the grid without a warning; Save JSON and Save CSV always download under the opened name, with no way to choose another (G10, G11, G14; prior S21, S22, S18). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Feature · State: accepted · 3 work items · 3 bullets

## 2. What you will see

Work in the browser is harder to lose. Ctrl+Z undoes the last change to the workbook, again and again, and Ctrl+Y (or Ctrl+Shift+Z) redoes it. If you try to reload or close the page with changes you haven't saved, the browser asks you to confirm first; after saving, it doesn't. A 'File name' box next to Save JSON / Save CSV holds the opened file's name, and you can type another name to save under.

- [a-v1-keep-work/README.md](https://github.com/alebairos/sheet-exp-host/blob/c1d7d20d3ccf3cf7fc12a729eb2ecaa062575af5/a-v1-keep-work/README.md)
- [a-v1-keep-work/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/c1d7d20d3ccf3cf7fc12a729eb2ecaa062575af5/a-v1-keep-work/prototype.diff)

## 3. Approach

Most value first: undo, because losing an edit with no way back is the commonest loss. All of it lives in web/io/index.html, which already owns every edit path (grid onChange, bar onCommit) and the save buttons.
WI 1 (undo/redo, about 15 lines): before each edit, push the workbook as typed (controller.state.book, immutable per edit) onto a past stack and clear the future stack. On Ctrl+Z (when focus is not in a text input, so typing keeps the browser's own text undo), move the current book to future, restore the previous one, recompute and redraw at the current selection. Ctrl+Y and Ctrl+Shift+Z do the reverse. Opening a file clears both stacks.
WI 2 (leave guard and save name, about 10 lines): a dirty flag is set by an edit, undo or redo and cleared by open and by either save. A beforeunload listener asks only while it is set. A 'File name' input (#save-name) before the save buttons is filled with the opened name; both saves use its value (an extension typed by the user is dropped and the right one added). The controller's saveJSON/saveCSV already name the download from state.name.
WI 3: tests/e2e/ui/test_keep_work.py.

Beliefs:
- ran: on main, Ctrl+Z after an edit changes nothing, a reload after an edit opens no confirmation and the edit is lost, and there is no way to choose the save name (no field, no dialog). Settled by a_v1_kw_b1_undo.sh, a_v1_kw_b2_unload.sh and a_v1_kw_b3_name.sh, all red on main.
- ran: the prototype (evidence prototype.diff, index.html +25) passes all three, and ./test.sh plus the a-i11, a-r0 and a-r2 checks still pass. Settled by the land test.
- ran: headless Chrome shows a beforeunload dialog to the DevTools client (Page.javascriptDialogOpening, type beforeunload) only after real user input, which b2 gives with a real click and key. A page with no edits and a just-saved page show none. Settled by b2.
- memory: browsers show their own generic leave text, not the page's. That is enough here ('asks for confirmation'). Settled by b2 and the judge.
- human: an in-page file name field is the 'choose the file name' the bullet asks for. A browser 'Save as' dialog (showSaveFilePicker) is Chromium-only and cannot be driven in a headless test. Settled by SpecAccept and the judge.

Learned from RECORD.md and the overlapping pages: a-i11's replan kept formulas on save by having the page hold the workbook as typed (controller.state.book); undo snapshots that same object, so undo cannot turn formulas into values. a-i11's attempt 1 multiplied engine calls per keypress, so undo/redo go through the same busy queue as edits, one compute each. The review's S21/S22/S18 are G10/G11/G14 here. Checks drive the page as shipped with real keys, as earlier UI intents learned to. Overlaps: a-v1-grid-keys and a-v1-big-sheets also change index.html (redraw at the current selection, which undo uses too), a-v1-sheet-tabs adds per-sheet state (undo covers the whole workbook, so it stays correct), and a-v1-csv-text changes what Save CSV writes, not its name.

- **Reuses:** The controller's state.book (the workbook as typed) and its save functions, the page's busy queue, compute, show() and message line, and the browser's beforeunload confirmation.
- **Removes:** none
- **Rejected:** Undo inside the grid only: edits also come from the formula bar, and the page is where both meet. A per-cell undo log: restoring whole workbook snapshots is simpler and cannot desynchronise formulas and values. window.prompt for the file name: it blocks the page and gets in the way when you only want a quick save. showSaveFilePicker: Chromium-only and not testable headless. Autosave to the server: out of scope.

## 4. Work items

### `wi-a-v1-keep-work-1`: Undo and redo

The page keeps the workbook as typed before each edit, so Ctrl+Z undoes edits from the grid or the formula bar several steps deep and Ctrl+Y / Ctrl+Shift+Z redoes them.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-kw-b1` | b1 | `tests/e2e/ui/checks/a_v1_kw_b1_undo.sh` | red | — |

### `wi-a-v1-keep-work-2`: Leave guard and save name

The page asks before leaving while there are unsaved edits (none after open or save), and a File name field lets the user choose the name Save JSON and Save CSV download under.

Status: accepted · depends on `wi-a-v1-keep-work-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-kw-b2` | b2 | `tests/e2e/ui/checks/a_v1_kw_b2_unload.sh` | red | — |
| `ac-kw-b3` | b3 | `tests/e2e/ui/checks/a_v1_kw_b3_name.sh` | red | — |

### `wi-a-v1-keep-work-3`: Product browser tests for keeping work

Adds tests/e2e/ui/test_keep_work.py, run by ./test.sh in headless Chrome, covering undo/redo, the leave confirmation and the chosen save name, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-keep-work-2`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-kw-suite` | b1, b2, b3 | `tests/e2e/ui/checks/a_v1_kw_suite.sh` | red | — |
| `ac-kw-judge` | b1, b2, b3 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user make a few changes, take them back and redo them with Ctrl+Z/Ctrl+Y, be warned before losing unsaved changes when reloading or closing, and save their work under a name they choose, all without surprises? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | Ctrl+Z undoes the last edit and Ctrl+Y redoes it, several steps deep | no landed check |
| not yet | b2 | leaving or reloading the page with unsaved edits asks for confirmation first | no landed check |
| not yet | b3 | saving lets the user choose the file name | no landed check |

## 5. Out of scope and risks

- **Out of scope:** autosave to a server
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/io/**`, `exp-a:web/grid/**`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-keep-work-1` | — |
| Reviewed `wi-a-v1-keep-work-1` | — |
| Implemented `wi-a-v1-keep-work-2` | — |
| Reviewed `wi-a-v1-keep-work-2` | — |
| Implemented `wi-a-v1-keep-work-3` | — |
| Reviewed `wi-a-v1-keep-work-3` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 3 h 10 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
