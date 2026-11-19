# Intent `a-i3-evaluator`

## 1. Outcome

> A parsed formula evaluates with Calc's operators and error propagation (#DIV/0!, #VALUE!, #REF!, #NAME?)

Kind: Feature · State: parked · 0 work items · 3 bullets

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | arithmetic, comparison, & and % match Calc | no landed check |
| not yet | b2 | errors propagate through operators as in Calc | no landed check |
| not yet | b3 | an unknown function is #NAME? | no landed check |

## 5. Out of scope and risks

- **Out of scope:** functions; recalculation order; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/eval/**`, `exp-a:tests/eval/**`

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
