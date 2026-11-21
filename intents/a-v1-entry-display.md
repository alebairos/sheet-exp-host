# Intent `a-v1-entry-display`

## 1. Outcome

> The same input gives different results depending on where I type it, and the grid shows numbers unlike Calc. Observed: 50% typed in the grid is stored as text (=A1*2 gives #VALUE!), in the formula bar it is 0.5, in a CSV it is text; =10^15+1 shows as 1E+15 in the grid (the CLI gives 1000000000000001), 1E-7 shows 1E-07 (G12, G16; prior S23, S25). Expected, as in Calc: one entry rule for grid, bar and CSV (50% is the number 0.5, shown 50%), and numbers shown as Calc's General format shows them. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

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
| not yet | b1 | 50%, 1e3, -2.5 and 'abc typed in the grid, typed in the formula bar, or read from a CSV become the same values (0.5, 1000, -2.5, text abc), as Calc enters them | no landed check |
| not yet | b2 | the grid shows numbers as Calc's General format does for a standard column width, with expected values taken from running LibreOffice | no landed check |

## 5. Out of scope and risks

- **Out of scope:** number formats chosen by the user
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/formula_bar/**`, `exp-a:web/io/io.js`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/formula_bar/**`, `exp-a:tests/web/io/**`

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
