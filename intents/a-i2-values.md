# Intent `a-i2-values`

## 1. Outcome

> Cell values and coercion behave as in Calc: numbers, text, booleans, blanks and the six errors, with text-to-number, boolean-as-1/0 and blank-as-0-or-empty

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
| not yet | b1 | each value kind round-trips through the CLI | no landed check |
| not yet | b2 | coercion between kinds matches Calc for arithmetic and comparison | no landed check |

## 5. Out of scope and risks

- **Out of scope:** formulas; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
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
