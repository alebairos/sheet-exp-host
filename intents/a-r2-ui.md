# Intent `a-r2-ui`

## 1. Outcome

> I can work in the spreadsheet in the browser: open a workbook, edit a formula, see the error, fix it, save

Kind: Feature · State: in work · 1 work item · 1 bullet

## 2. What you will see

The app page (python3 web/io/serve.py, then /io/index.html) gets the formula bar above the grid: click a cell and the bar shows its formula as typed (B1 fx =A1/A2) and, when the cell computes to an error, the error's name next to it in red; type a new formula in the bar and press Enter and the grid recomputes. So the whole walk-through works in the browser: Open walk.json, click B1 (shows 5, bar =A1/A2), change it to =A1/A3, see #DIV/0! in the cell and in the bar, change it to =A1/A2*3, see 15 and no error, Save JSON and get the fixed formula back in the file. A headless Chrome/Chromium test does exactly that with real clicks and keys and runs in ./test.sh. The media shows the three states on a prototype of the page change.

- [a-r2-ui/README.md](https://github.com/alebairos/sheet-exp-host/blob/9f426e687ab60c244829d7d2e791aa22a081bd41/a-r2-ui/README.md)
- [a-r2-ui/1-opened.png](https://github.com/alebairos/sheet-exp-host/blob/9f426e687ab60c244829d7d2e791aa22a081bd41/a-r2-ui/1-opened.png)
- [a-r2-ui/2-error.png](https://github.com/alebairos/sheet-exp-host/blob/9f426e687ab60c244829d7d2e791aa22a081bd41/a-r2-ui/2-error.png)
- [a-r2-ui/3-fixed.png](https://github.com/alebairos/sheet-exp-host/blob/9f426e687ab60c244829d7d2e791aa22a081bd41/a-r2-ui/3-fixed.png)
- [a-r2-ui/prototype-index.html.diff](https://github.com/alebairos/sheet-exp-host/blob/9f426e687ab60c244829d7d2e791aa22a081bd41/a-r2-ui/prototype-index.html.diff)

## 3. Approach

Most value first: the missing piece is on the page, not in the parts. Today web/io/index.html mounts only the grid, whose cells hold computed values, so a formula can be neither seen nor edited in place (the walk-through stops at step 1). The WI mounts web/formula_bar's bar (mount(container, {ref, raw, computed, sheet}, {onCommit})) in a new #formula-bar element above #grid, keeps the selected ref from the grid's onChange, feeds the bar controller.state.book (as typed) and .computed, and sends a bar commit to controller.edit(ref, text), then redraws grid and bar with the cell still selected; a few lines of CSS for the bar are fine. About 30 changed lines of the page; web/io/README.md notes the bar. Then the product's own browser test in tests/e2e/ui (tests/e2e/ui/__init__.py plus a unittest that ./test.sh discovers): start web/io/serve.py on a free port and headless Chrome/Chromium (browser from $CHROME first, then google-chrome, chromium on PATH; skipped only when there is no browser or node) and walk the steps above; it may drive the browser over --remote-debugging-pipe from Node's standard library as the check's a_r2_cdp.mjs does (no npm, no Playwright, nothing to install: the repo stays standard-library only). The check runs its own walk-through and also requires the product test to start the $CHROME browser, not be skipped, and pass.

- **Reuses:** web/io's controller (openFile, edit, saveJSON), serve.py and its POST /compute, the grid (mount, onChange with the selection) and the formula bar (mount, update, onCommit, its .error span) as they are; the engine through serve.py.
- **Removes:** none
- **Rejected:** A test-only intent (the scope as parked, tests/e2e/ui only): the page has no formula bar, so no test can edit a formula or see it, and the walk-through could not pass; the scope adds web/io/index.html (the page that wires the parts) and its README, while the parts' code (grid.js, formula_bar.js, io.js, serve.py) stays forbidden. Editing the formula inside the grid cell: the grid shows computed values, so F2 on a formula cell offers its value and would overwrite the formula; changing that is changing the grid. Playwright or Puppeteer: an npm install and a downloaded browser in a repo that has none; the DevTools pipe needs only Node and the Chrome already on the runner. A jsdom or Node-only test of the controller: that is a-i11's test already, and it is not a browser.

## 4. Work items

### `wi-a-r2-ui-1`: Formula bar on the app page, browser walk-through test

Puts the formula bar above the grid on the app page (web/io/index.html) so you can see and edit a cell's formula and its error, and adds a headless-browser test that opens a workbook, edits a formula, sees #DIV/0!, fixes it and saves, so ./test.sh guards the whole UI.

Status: landing (`fa207f2b6389`)

**The passing review noted:** > PASS (attempt 2), wi-a-r2-ui-1 @ fd125ae (plan fcfcc8d). It already contains current exp-a main (e2731, which has a-r1-engine).
> - Attempt 1's blocking finding is fixed (web/io/index.html:61-78). onCommit now puts the bar's committed value into controller.state.book as is, then recomputes through the page's own compute, with a "Could not compute" message on error, the same way io.js does it. It no longer re-enters the value as grid text.
> - Reproduced again with my attempt-1 probe in Chromium, real clicks and keys: Enter on '007 keeps A1 the text "007" (ISTEXT TRUE), typing '42 stores the text "42", and Save JSON writes {"A1":"007","A2":"42",...}. Attempt 1 gave 7 and 42.
> - The product test guards it now: tests/e2e/ui/walkthrough.mjs:97-112 (step 6) opens a text workbook, presses Enter on '007, types '42 and checks the saved JSON.
> - ac-r2-b1 (b1): tests/e2e/ui/checks/a_r2_b1_walkthrough.sh prints "ok walk-through ... ok". ./test.sh runs 67 tests, all OK, and the browser test runs, not skipped. On base (fcfcc8d) the check was red, as reported on attempt 1.
> - Scope: the diff since attempt 1 touches only web/io/index.html and tests/e2e/ui/walkthrough.mjs, both in scope. The parts are untouched.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r2-b1` | b1 | `tests/e2e/ui/checks/a_r2_b1_walkthrough.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | that walk-through runs end to end in a browser test | no landed check |

## 5. Out of scope and risks

- **Out of scope:** changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:tests/e2e/ui/**`, `exp-a:web/io/index.html`, `exp-a:web/io/README.md`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-r2-ui-1` | `impl-a1@alebairos`, `impl-a2@alebairos` |
| Reviewed `wi-a-r2-ui-1` | `rev-a@alebairos` (passed attempt 2) |

Product checks: not recorded yet.

Outcome report: none yet.

Landing pull request: [exp-a #19](https://github.com/alebairos/sheet-exp-a/pull/19)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 25 h 34 min so far
- Loops: 1 (D5 review 1)
- Waste: 7 min
- Size: nothing landed yet
