# Intent `a-i4-recalc`

## 1. Outcome

> A workbook recalculates in dependency order, recomputes only what an edit affects, and reports a circular reference as an error instead of hanging

Kind: Feature · State: parked · 0 work items · 4 bullets

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | chains of formula cells compute in dependency order | no landed check |
| not yet | b2 | an edit recomputes only its dependents | no landed check |
| not yet | b3 | a cycle gives an error | no landed check |
| not yet | b4 | 10,000 dependent cells recompute in under one second | no landed check |

## 5. Out of scope and risks

- **Out of scope:** functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Path scope:** `exp-a:src/recalc/**`, `exp-a:tests/recalc/**`

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
