# Intent `a-r1-engine`

## 1. Outcome

> The engine computes whole workbooks end to end through the CLI: formulas, functions and recalculation together

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
| not yet | b1 | multi-sheet workbooks mixing every function group compute as Calc does | no landed check |
| not yet | b2 | a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the UI; changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:tests/e2e/engine/**`

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
