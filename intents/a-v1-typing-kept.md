# Intent `a-v1-typing-kept`

## 1. Outcome

> In the browser, keystrokes typed while the workbook recomputes are lost. Observed: on a workbook that takes ~2.7 s to compute, type 1 and Enter, then at once type a long formula at 120 ms per key: when the recompute returns the redraw removes the open editor, the formula is lost or a partial one committed, and focus goes to BODY. Expected: every keystroke typed lands in the cell being edited, whatever the engine is doing (G4; prior S14, "data-loss"). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: parked · 0 work items · 2 bullets

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | text typed into a cell while a recompute is in flight is kept in full and committed only when the user presses Enter | no landed check |
| not yet | b2 | after a recompute returns, the cell being edited is still open with its text and caret, and focus stays in the grid | no landed check |

## 5. Out of scope and risks

- **Out of scope:** making the engine faster
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | — |
| Certified | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

Not started: the metrics start with the first plan.
