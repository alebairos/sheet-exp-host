# Intent `a-v1-grid-keys`

## 1. Outcome

> Moving around the browser grid loses my place or my text. Observed: Tab on A1 leaves the selection on A1 and moves focus to BODY; typing 77 then Tab commits but stays; clicking another cell while editing commits but leaves the old cell selected; text typed in the formula bar is silently dropped when you click away (G7, G8, G9; prior S13). Expected, as in Calc: Tab commits and moves right, Shift+Tab left; a click while editing commits and selects the clicked cell; leaving the bar commits what was typed. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: parked · 0 work items · 3 bullets

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

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
| Planned | — |
| Certified | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

Not started: the metrics start with the first plan.
