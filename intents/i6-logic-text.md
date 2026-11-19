# Intent `i6-logic-text`

## 1. Outcome

> The 9 logic and information functions and the 8 text functions of SPEC.md compute as in Calc

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
| not yet | b1 | IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT, ISERROR match Calc | no landed check |
| not yet | b2 | CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM match Calc, coercion and errors included | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/functions/logic_text/**`, `exp-b:tests/functions/logic_text/**`

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
