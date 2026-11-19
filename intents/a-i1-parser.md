# Intent `a-i1-parser`

## 1. Outcome

> Formulas parse as Calc reads them: A1, $A$1, ranges, Sheet2!A1, every SPEC.md operator with Calc's precedence (including -A1^2 and 2^3^2), numbers, strings, booleans and function calls

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
| not yet | b1 | references, ranges and sheet references parse | no landed check |
| not yet | b2 | operator precedence and associativity match Calc | no landed check |
| not yet | b3 | a malformed formula is a parse error, not a crash | no landed check |

## 5. Out of scope and risks

- **Out of scope:** evaluation; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/parser/**`, `exp-a:tests/parser/**`

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
