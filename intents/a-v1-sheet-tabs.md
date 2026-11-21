# Intent `a-v1-sheet-tabs`

## 1. Outcome

> I can reach and edit every sheet of a workbook in the browser. Observed: opening order.json (sheets Prices and Order) shows only Prices with no tabs or selector, and typing 5 in B1 changes Prices!B1; Order!B1 can't be changed, so the CLI then prints 61.83, not 72.63 (G6; prior S20, T12 = 0). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Feature · State: parked · 0 work items · 2 bullets

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

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
| Planned | — |
| Certified | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

Not started: the metrics start with the first plan.
