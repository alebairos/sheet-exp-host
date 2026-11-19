# Intent `i5-math`

## 1. Outcome

> The 20 math and statistics functions of SPEC.md compute as in Calc, including ranges, blanks, text in ranges, and ROUND's half-away-from-zero

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
| not yet | b1 | SUM, AVERAGE, MIN, MAX, COUNT, COUNTA, PRODUCT, MEDIAN, STDEV match Calc on ranges with blanks and text | no landed check |
| not yet | b2 | ROUND, ROUNDUP, ROUNDDOWN, INT, MOD, ABS, POWER, SQRT match Calc, errors included | no landed check |
| not yet | b3 | SUMIF, COUNTIF, AVERAGEIF match Calc's criteria | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/functions/math/**`, `exp-b:tests/functions/math/**`

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
