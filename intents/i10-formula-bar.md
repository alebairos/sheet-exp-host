# Intent `i10-formula-bar`

## 1. Outcome

> In the browser a formula bar shows the selected cell's formula, and a cell in error shows the error

Kind: Feature · State: awaiting the verdict · 1 work item · 2 bullets

## 2. What you will see

Above the grid, a bar like Calc's: the selected cell's name (B1), then its content as typed: the formula =A1/A2 rather than its value, or the constant (1, 2.5, TRUE, text). Edit it and press Enter to change the cell (a text starting with = stays a formula; 42 becomes a number, TRUE a boolean, empty text a blank cell); Escape cancels. When the cell's computed value is an error, its name shows in red next to the formula, exactly as Calc names it: #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A or #NUM!. Text that merely looks like an error (a constant "#DIV/0!") is not flagged. The clickable prototype in the media is that screen with sample cells.

- [i10-formula-bar/prototype.html](https://github.com/alebairos/sheet-exp-host/blob/920f66114e6844ec076654e5516da4397a499a6e/i10-formula-bar/prototype.html)
- [i10-formula-bar/formula_bar.js](https://github.com/alebairos/sheet-exp-host/blob/920f66114e6844ec076654e5516da4397a499a6e/i10-formula-bar/formula_bar.js)

## 3. Approach

One plain ES module, web/formula_bar/formula_bar.js, no build and no libraries, pure functions first so Node tests them without a browser: barText(raw, sheet, ref) reads the workbook as typed (SPEC.md's JSON, formulas kept) and formats constants as Calc shows them (15 significant digits, TRUE/FALSE); errorText(computed, sheet, ref) reads the computed workbook (./engine's output) and returns an error's name or ""; commit(raw, sheet, ref, text) returns a new workbook with the cell set (= keeps a formula, else number/boolean/text, "" removes the cell; the input is not mutated); renderHTML({raw, computed, sheet, ref}) returns the bar with the cell name, an input holding the HTML-escaped text and, only for an error, an element with class error. mount(container, state, {onCommit}) is the only DOM code: it draws the bar, commits on Enter, cancels on Escape, and returns update({ref, raw, computed}) so the page can follow the grid's selection. It is self-contained (no import from web/grid), so it does not wait on the grid's files; the page that joins grid, bar and the engine comes with open/save. The plan checks (tests/web/formula_bar/checks) run under Node.js, on the land runner image.

- **Reuses:** The web/formula_bar directory from i0-skeleton; SPEC.md's workbook JSON as typed and as computed (errors as {"error": "#DIV/0!"}); the grid's typed-input rules from i9-grid (number, TRUE/FALSE, text, empty is blank), so both edit the same way.
- **Removes:** The placeholder web/formula_bar/.gitkeep, replaced by the formula bar module and a short note on its API.
- **Rejected:** Importing web/grid/grid.js for formatting and input parsing: it is a dependency on files not yet landed and couples two directories owned by different intents; the few lines are kept local and the checks pin the same behavior. Calc's long error messages (Err:502, "Division by zero" in the status bar): the SPEC names the six codes and the hidden suite compares them. A framework or bundler: needs npm and a build in every clean clone.

## 4. Work items

### `wi-i10-formula-bar-1`: Formula bar UI

Add web/formula_bar/formula_bar.js so the selected cell's formula shows and edits in a bar and Calc error names appear in red, proven by the two plan checks.

Status: landed (`4ebacdf52b8c`)

**The passing review noted:** > pass wi-i10-formula-bar-1 (commit 374d839c0bda76a6467db3a0b0bbec4161796cfa)
> 
> ac-b1 (b1: formula bar shows and edits the selected cell's formula): PASS
> - reran tests/web/formula_bar/checks/b1_formula.sh → exit 0 (ok b1)
> - barText/typedText: web/formula_bar/formula_bar.js:27-38 (formulas kept as typed)
> - parseInput/commit: web/formula_bar/formula_bar.js:47-70 (= stays formula; number/TRUE/FALSE/blank)
> - renderHTML/mount Enter-Escape: web/formula_bar/formula_bar.js:73-113
> 
> ac-b2 (b2: errors display as Calc names them): PASS
> - reran tests/web/formula_bar/checks/b2_errors.sh → exit 0 (ok b2)
> - errorText: web/formula_bar/formula_bar.js:41-44 (only {error: "..."} objects)
> - renderHTML error span: web/formula_bar/formula_bar.js:73-82
> 
> suite: ./test.sh → all tests passed (exit 0)
> 
> scope: exp-b:web/formula_bar/** and exp-b:tests/web/formula_bar/** only
> - includes README.md documenting API (belongs under web/formula_bar)
> - plan checks under tests/web/formula_bar; law 9 drops check-file edits at land
> - no path outside scope

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/web/formula_bar/checks/b1_formula.sh` | red | pass |
| `ac-b2` | b2 | `tests/web/formula_bar/checks/b2_errors.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | the formula bar shows and edits the selected cell's formula | `tests/web/formula_bar/checks/b1_formula.sh` pass |
| PASS | b2 | errors display as Calc names them | `tests/web/formula_bar/checks/b2_errors.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** file handling; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:web/formula_bar/**`, `exp-b:tests/web/formula_bar/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i10-formula-bar-1` | `impl-2@alebairos` |
| Reviewed `wi-i10-formula-bar-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks:

- `tests/web/formula_bar/checks/b1_formula.sh`: pass
- `tests/web/formula_bar/checks/b2_errors.sh`: pass

Outcome report:

- **Built:** Above the grid, a bar like Calc's: the selected cell's name (B1), then its content as typed: the formula =A1/A2 rather than its value, or the constant (1, 2.5, TRUE, text). Edit it and press Enter to change the cell (a text starting with = stays a formula; 42 becomes a number, TRUE a boolean, empty text a blank cell); Escape cancels. When the cell's computed value is an error, its name shows in red next to the formula, exactly as Calc names it: #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A or #NUM!. Text that merely looks like an error (a constant "#DIV/0!") is not flagged. The clickable prototype in the media is that screen with sample cells.
- **Advice:** adopt
- [i10-formula-bar/prototype.html](https://github.com/alebairos/sheet-exp-host/blob/920f66114e6844ec076654e5516da4397a499a6e/i10-formula-bar/prototype.html)
- [i10-formula-bar/formula_bar.js](https://github.com/alebairos/sheet-exp-host/blob/920f66114e6844ec076654e5516da4397a499a6e/i10-formula-bar/formula_bar.js)

Files landed by `wi-i10-formula-bar-1`:

- `web/formula_bar/formula_bar.js` +113 −0
- `tests/web/formula_bar/checks/b1_formula.sh` +46 −0 (plan check)
- `tests/web/formula_bar/checks/b2_errors.sh` +33 −0 (plan check)
- `web/formula_bar/README.md` +11 −0
- `tests/web/formula_bar/__init__.py` +1 −0 (plan check)
- `web/formula_bar/.gitkeep` +0 −1

Landing pull request: [exp-b #6](https://github.com/alebairos/sheet-exp-b/pull/6)

## 7. The decision

**Verdict:i10-formula-bar**: A decision: show your human its options

- Met: `cooknship decide --answer Verdict:i10-formula-bar --option met`
- Partially met: unmet bullets park as follow-ups: `cooknship decide --answer Verdict:i10-formula-bar --option partially`
- Not met: every unmet bullet parks as a follow-up: `cooknship decide --answer Verdict:i10-formula-bar --option not_met`

## 8. Metrics

- Lead time: 10 h 36 min so far
- Loops: 0
- Waste: 0 min
- Size: 125 lines (+124 −1, 3 files, ≤400; tests 0 lines); plan check files laid over by land, not in the size: +80 −0, 3 files
