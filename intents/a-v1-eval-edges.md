# Intent `a-v1-eval-edges`

## 1. Outcome

> Two Calc evaluation rules are missing. Observed vs LibreOffice: =C2:C3 in row 2 gives #VALUE! (Calc 3, implicit intersection); =IF(TRUE,1,A16) in A16 gives Err:522 (Calc 1), =IF(FALSE,B7,2) in B7 Err:522 (Calc 2), and B8 =IFERROR(B9,0) with B9 =B8 gives Err:522 for B8 (Calc 0) (G20, G22). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

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
| not yet | b1 | a range used where one value is expected takes the cell in the formula's row or column, as LibreOffice does, on cases computed by LibreOffice | no landed check |
| not yet | b2 | a self-reference through a branch IF or IFERROR does not take gives LibreOffice's value, not Err:522, on cases computed by LibreOffice | no landed check |

## 5. Out of scope and risks

- **Out of scope:** iterative calculation
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/eval/**`, `exp-a:src/recalc/**`, `exp-a:tests/eval/**`, `exp-a:tests/recalc/**`

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
