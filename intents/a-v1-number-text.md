# Intent `a-v1-number-text`

## 1. Outcome

> Numbers turned into text differ from Calc. Observed vs LibreOffice 26.8.1.1: "x"&1E-7 gives x1E-07 (Calc x0.0000001); "x"&1E15 x1E+15 (Calc x1000000000000000); CONCATENATE(1E21) 1E+21 (Calc 1E+021); LEN(123456789012345678) 20 and LEN(1E-20) 5 (Calc 21 and 6). Suggested by a-i6 and never parked (G23). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: parked · 0 work items · 1 bullet

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | number-to-text conversion in &, CONCATENATE, LEN and the text functions matches LibreOffice over a set of small, large and fractional numbers, with expected values from running LibreOffice | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the grid's display (a-v1-entry-display)
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/values/**`, `exp-a:tests/values/**`

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
