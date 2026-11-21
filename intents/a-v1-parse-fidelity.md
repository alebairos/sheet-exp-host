# Intent `a-v1-parse-fidelity`

## 1. Outcome

> Formulas Calc accepts fail here, and malformed ones give the wrong error. Observed vs LibreOffice: = SUM( A1 : A2 ) gives #VALUE! (Calc 3); =SUM( 'My Sheet'!A1 : A2 ) #VALUE! (Calc 11); =SUM(S2!A1:S2!A2) #VALUE! (Calc 7); =SUM(1,2 #VALUE! (Calc 3); =(1+ and =1+*2 give #VALUE! (Calc Err:511, Err:510); =1E400 #VALUE! (Calc Err:502); =MAX() 0 and =MEDIAN() #VALUE! (Calc Err:511) (G24, G25; prior S15, S24). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

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
| not yet | b1 | formulas with spaces around tokens, ranges with a sheet on both ends, and a missing final parenthesis compute as LibreOffice computes them | no landed check |
| not yet | b2 | malformed formulas, =1E400 and empty-argument calls give LibreOffice's error codes, with expected values from running LibreOffice | no landed check |

## 5. Out of scope and risks

- **Out of scope:** array literals and whole-column references
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/parser/**`, `exp-a:src/eval/**`, `exp-a:src/recalc/**`, `exp-a:tests/parser/**`, `exp-a:tests/eval/**`, `exp-a:tests/recalc/**`

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
