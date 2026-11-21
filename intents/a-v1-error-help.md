# Intent `a-v1-error-help`

## 1. Outcome

> When a cell shows an error in the browser, I'm told what went wrong. Observed: =(1+ shows #VALUE!, a circular reference shows Err:522, =SQRT(-1) shows Err:502, all with an empty message line (G13, G30; prior S5, S7, S15). Conflict noted by the review: SPEC lists six error names; Calc shows Err:5xx, and the hidden suite expects Calc's, so the engine keeps them and the UI explains them. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Feature · State: accepted · 2 work items · 2 bullets

## 2. What you will see

Click a cell that shows an error and, next to the formula bar, one plain line says what it means in LibreOffice Calc's own words, with the usual cause: 'Err:522: Circular reference: the formula depends on its own cell.', '#DIV/0!: Division by zero: ...', 'Err:502: Invalid argument: ...', and so on for #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A, #NUM!, Err:502, Err:504, Err:511 and Err:522. Cells without an error show no line. The engine and its CLI output are unchanged: the error names stay Calc's. Screen: evidence 1-err522-selected.png.

- [a-v1-error-help/README.md](https://github.com/alebairos/sheet-exp-host/blob/0b6b0e89f9c7a65b3d3042110c7fbc547ee061df/a-v1-error-help/README.md)
- [a-v1-error-help/1-err522-selected.png](https://github.com/alebairos/sheet-exp-host/blob/0b6b0e89f9c7a65b3d3042110c7fbc547ee061df/a-v1-error-help/1-err522-selected.png)
- [a-v1-error-help/calc-long-texts.tsv](https://github.com/alebairos/sheet-exp-host/blob/0b6b0e89f9c7a65b3d3042110c7fbc547ee061df/a-v1-error-help/calc-long-texts.tsv)
- [a-v1-error-help/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/0b6b0e89f9c7a65b3d3042110c7fbc547ee061df/a-v1-error-help/prototype.diff)

## 3. Approach

Most value first: the explanation where the user is already looking. The formula bar already shows a selected error's name in red (a-i10), so web/formula_bar/formula_bar.js gets an ERROR_HELP table, one entry per error. renderHTML adds, for an error cell only, a span.error-help that reads '<name>: <Calc's explanation>: <a short usual cause>', e.g. 'Err:522: Circular reference: the formula depends on its own cell.' The line must fit the window (for example on its own line under the bar, styled in web/io/index.html). The prototype's line runs past the edge at 1000 px. Nothing in the engine changes, so the CLI prints exactly what it does today (b2). One WI for the bar (about 20 lines plus CSS), one for the product's own test, tests/e2e/ui/test_error_help.py, which shows the ten explanations in a browser and pins the CLI's error names.

Beliefs:
- ran: on main, selecting an error cell shows only its name (#formula-bar .error) and nothing explains it. Settled by a_v1_eh_b1_help.sh, red on main.
- ran: LibreOffice Calc 26.8.1.1 gives exactly these ten errors for the ten formulas of a_v1_eh_calc.json (codes 532, 519, 524, 525, 32767, 503, 502, 504, 511, 522), and so does ./engine today (run by hand). Settled by b1 (the grid shows them) and by the suite check's CLI pin (b2).
- ran: Calc's own one-line explanations are its STR_LONG_ERR_* texts, read from the installed libsclo.so by a_v1_eh_probe.py ('Error: Circular reference', 'Error: Division by zero', ...). In 26.8 the text for #VALUE! (NO_VALUE) is 'Error: No value'. Settled by b1, which requires those words.
- memory: STR_LONG_ERR_* names map to the error codes as in LibreOffice's source (DIV_ZERO 532, NO_VALUE 519, NO_REF 524, NO_NAME 525, NV 32767, ILL_FPO 503, ILL_ARG 502, ILL_PAR 504, VAR_EXP 511, CIRC_REF 522). Settled by: the probe's computed codes for each formula agree with the mapping.
- ran: the prototype (evidence prototype.diff) passes b1, and ./test.sh plus a-i10's and a-r2's checks still pass. Settled by the land test.
- human: the review's conflict note (SPEC names six errors, Calc shows Err:5xx) is settled by the parked outcome: the engine keeps Calc's names and the UI explains them. Settled by SpecAccept.
- ran (side finding, out of scope): =ROUND() with no argument crashes ./engine with a Python TypeError instead of Err:511. Reported to the Gm for an intent of its own.

Learned from RECORD.md and the overlapping pages: Err:502/504/511/522 were kept as Calc shows them by a-i4/a-i5/a-i6/a-i7 and flagged each time as 'a one-line change'. The review found them cryptic (S5, S7), so the fix explains them instead of renaming them, which keeps the hidden suite's Calc names. a-i10 rejected 'Calc's long error messages' because SPEC names the six codes, and this reverses that for the UI only, with Calc's own words. a-i10 noted ERROR_NAMES unused and listing #NULL!; the new table lists exactly the ten errors the engine emits. The checks go through the shipped page with real clicks and require Calc's text, not wording made up for them. Overlaps: a-v1-entry-display (bar parsing), a-v1-grid-keys (bar commit on blur), a-v1-cell-edit and a-v1-sheet-tabs share index.html. This plan adds a span and its style only.

- **Reuses:** The formula bar's errorText and its red .error span, its renderHTML/update cycle that follows the grid's selection, the page's styles in web/io/index.html, and a_r2_cdp.mjs for the browser check.
- **Removes:** none
- **Rejected:** Renaming Err:5xx to SPEC's six names in the engine: the hidden suite is computed by LibreOffice and expects Calc's names, and the intent puts that out of scope. Tooltips on hover in the grid: invisible on keyboard use and harder to test. A message in the page's message line: it reports file and compute status and would be overwritten. Explanations in our own words only: the reference is Calc, whose status bar already has a text for each error, so we use its words and add a short cause.

## 4. Work items

### `wi-a-v1-error-help-1`: Explain the selected error beside the bar

The formula bar shows, for a selected error cell, one line naming the error with Calc's own explanation and a short usual cause (Err:522: Circular reference ...), so users learn what went wrong while the engine's error names stay Calc's.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-eh-b1` | b1 | `tests/e2e/ui/checks/a_v1_eh_b1_help.sh` | red | — |

### `wi-a-v1-error-help-2`: Product tests for error help and CLI names

Adds tests/e2e/ui/test_error_help.py, run by ./test.sh, which shows the ten explanations in a browser and pins ./engine's printed error names for the same formulas, so the help stays and the CLI does not change.

Status: accepted · depends on `wi-a-v1-error-help-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-eh-suite` | b1, b2 | `tests/e2e/ui/checks/a_v1_eh_suite.sh` | red | — |
| `ac-eh-judge` | b1 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), when an ordinary user makes everyday mistakes (dividing by an empty cell, a typo in a function name, a circular reference, SQRT of a negative number, a lookup that finds nothing) and clicks the error cell, do they understand from the line beside the formula bar what went wrong and what to fix? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | selecting a cell whose value is an error shows a one-line plain-language explanation beside the formula bar for each of #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A, #NUM!, Err:502, Err:504, Err:511, Err:522 (e.g. Err:522: circular reference) | no landed check |
| not yet | b2 | the engine CLI output for these errors is unchanged | no landed check |

## 5. Out of scope and risks

- **Out of scope:** changing the error codes the engine emits
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/formula_bar/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/formula_bar/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-error-help-1` | — |
| Reviewed `wi-a-v1-error-help-1` | — |
| Implemented `wi-a-v1-error-help-2` | — |
| Reviewed `wi-a-v1-error-help-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 10 h 44 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
