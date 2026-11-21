# Intent `a-v1-error-help`

## 1. Outcome

> When a cell shows an error in the browser, I'm told what went wrong. Observed: =(1+ shows #VALUE!, a circular reference shows Err:522, =SQRT(-1) shows Err:502, all with an empty message line (G13, G30; prior S5, S7, S15). Conflict noted by the review: SPEC lists six error names; Calc shows Err:5xx, and the hidden suite expects Calc's, so the engine keeps them and the UI explains them. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

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
| not yet | b1 | selecting a cell whose value is an error shows a one-line plain-language explanation beside the formula bar for each of #DIV/0!, #VALUE!, #REF!, #NAME?, #N/A, #NUM!, Err:502, Err:504, Err:511, Err:522 (e.g. Err:522: circular reference) | no landed check |
| not yet | b2 | the engine CLI output for these errors is unchanged | no landed check |

## 5. Out of scope and risks

- **Out of scope:** changing the error codes the engine emits
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/formula_bar/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/formula_bar/**`, `exp-a:tests/web/io/**`

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
