# Intent `a-i10-formula-bar`

## 1. Outcome

> In the browser a formula bar shows the selected cell's formula, and a cell in error shows the error

Kind: Feature · State: awaiting the verdict · 1 work item · 2 bullets

## 2. What you will see

Above the grid, a bar like Calc's: the selected cell's name (B1), then its content as typed: the formula =A1/A2 rather than its value, or the constant (1, 2.5, TRUE, text). Edit it and press Enter to change the cell (a text starting with = stays a formula; 42 becomes a number, TRUE a boolean, empty text a blank cell); Escape cancels. When the cell's computed value is an error, its name shows in red next to the formula, exactly as Calc names it: #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A or #NUM!. Text that merely looks like an error (a constant "#DIV/0!") is not flagged. The clickable prototype in the media is that screen with sample cells.

- [a-i10-formula-bar/prototype.html](https://github.com/alebairos/sheet-exp-host/blob/f2a46239912f4322eee823cadb7af6393fec3768/a-i10-formula-bar/prototype.html)
- [a-i10-formula-bar/formula_bar.js](https://github.com/alebairos/sheet-exp-host/blob/f2a46239912f4322eee823cadb7af6393fec3768/a-i10-formula-bar/formula_bar.js)

## 3. Approach

One plain ES module, web/formula_bar/formula_bar.js, no build and no libraries, pure functions first so Node tests them without a browser: barText(raw, sheet, ref) reads the workbook as typed (SPEC.md's JSON, formulas kept) and formats constants as Calc shows them (15 significant digits, TRUE/FALSE); errorText(computed, sheet, ref) reads the computed workbook (./engine's output) and returns an error's name or ""; commit(raw, sheet, ref, text) returns a new workbook with the cell set (= keeps a formula, else number/boolean/text, "" removes the cell; the input is not mutated); renderHTML({raw, computed, sheet, ref}) returns the bar with the cell name, an input holding the HTML-escaped text and, only for an error, an element with class error. mount(container, state, {onCommit}) is the only DOM code: it draws the bar, commits on Enter, cancels on Escape, and returns update({ref, raw, computed}) so the page can follow the grid's selection. It is self-contained (no import from web/grid), so it does not wait on the grid's files; the page that joins grid, bar and the engine comes with open/save. The plan checks (tests/web/formula_bar/checks) run under Node.js, on the land runner image.

- **Reuses:** The web/formula_bar directory from a-i0-skeleton; SPEC.md's workbook JSON as typed and as computed (errors as {"error": "#DIV/0!"}); the grid's typed-input rules from a-i9-grid (number, TRUE/FALSE, text, empty is blank), so both edit the same way.
- **Removes:** The placeholder web/formula_bar/README.md content, replaced by a short note on the module's API.
- **Rejected:** Importing web/grid/grid.js for formatting and input parsing: it is a dependency on files not yet landed and couples two directories owned by different intents; the few lines are kept local and the checks pin the same behavior. Calc's long error messages (Err:502, "Division by zero" in the status bar): the SPEC names the six codes and the hidden suite compares them. A framework or bundler: needs npm and a build in every clean clone.

## 4. Work items

### `wi-a-i10-formula-bar-1`: Formula bar: show, edit, errors

Add web/formula_bar: a dependency-free JavaScript module that shows the selected cell's name and its formula as typed, lets you edit and commit it with Enter, and shows the cell's error by Calc's name (#DIV/0!, #VALUE!, #REF!, #NAME?, #N/A, #NUM!), so the UI can see and change formulas, not just values.

Status: landed (`fd1b4ba07198`)

**The passing review noted:** > PASS. Verify rerun in a worktree of WI commit fe7051e: tests/web/formula_bar/checks/a10_b1_formula.sh -> "ok b1" (exit 0), a10_b2_errors.sh -> "ok b2" (exit 0); on plan base 052e9af both exit 1 (module missing). ./test.sh green (10 tests); node --test tests/web/formula_bar/ 6/6 pass.
> ac-a10-b1 (b1, shows and edits the formula): barText returns the raw formula/constant (web/formula_bar/formula_bar.js:45-47 via typedText :30-42: TRUE/FALSE, 15 significant digits, apostrophe for text that reads as a value); commit parses the bar text into a new workbook without mutating input, "" blanks the cell (:71-80, parseInput :57-68); renderHTML shows the cell name and an HTML-escaped input (:83-93); mount commits on Enter, cancels on Escape, update() follows the selection (:97-122).
> ac-a10-b2 (b2, errors as Calc names them): errorText reads only computed {error: name} objects, so constant text "#DIV/0!" is not flagged (:51-54); renderHTML adds <span class="error"> only for an error (:90).
> Scope: all 5 paths are under web/formula_bar/** and tests/web/formula_bar/**; no check file edited.
> Findings (non-blocking): (1) tests/web/formula_bar/test_formula_bar.py is never run by ./test.sh: unittest discover does not descend into tests/web, which has no __init__.py (outside this intent's scope), so the Node unit tests only run by hand; the plan checks still gate b1/b2. (2) formatNumber shows 1e-7 as "1E-7" and 50% (committed as 0.5) as "0.5"; Calc's input line shows 0.0000001 and 50%. This is a cosmetic difference, not covered by the bullets. (3) ERROR_NAMES (:8) is exported but unused, and it includes #NULL!, which SPEC's six codes leave out.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a10-b1` | b1 | `tests/web/formula_bar/checks/a10_b1_formula.sh` | red | — |
| `ac-a10-b2` | b2 | `tests/web/formula_bar/checks/a10_b2_errors.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | the formula bar shows and edits the selected cell's formula | `tests/web/formula_bar/checks/a10_b1_formula.sh` — |
| not yet | b2 | errors display as Calc names them | `tests/web/formula_bar/checks/a10_b2_errors.sh` — |

## 5. Out of scope and risks

- **Out of scope:** file handling; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:web/formula_bar/**`, `exp-a:tests/web/formula_bar/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i10-formula-bar-1` | `impl-a1@alebairos` |
| Reviewed `wi-a-i10-formula-bar-1` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-i10-formula-bar-1`:

- `web/formula_bar/formula_bar.js` +123 −0
- `tests/web/formula_bar/formula_bar.test.mjs` +81 −0 (test)
- `tests/web/formula_bar/checks/a10_b1_formula.sh` +46 −0 (plan check)
- `tests/web/formula_bar/checks/a10_b2_errors.sh` +33 −0 (plan check)
- `tests/web/formula_bar/test_formula_bar.py` +21 −0 (test)
- `web/formula_bar/README.md` +9 −1
- `tests/web/formula_bar/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #6](https://github.com/alebairos/sheet-exp-a/pull/6)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 8 h 47 min so far
- Loops: 0
- Waste: 0 min
- Size: 133 lines (+132 −1, 5 files, ≤400; tests 102 lines); plan check files laid over by land, not in the size: +79 −0, 2 files
