# Intent `a-v1-text-rules`

## 1. Outcome

> Text is compared and converted unlike Calc. Observed vs LibreOffice: ="a"="A" gives TRUE (Calc FALSE, case-sensitive by default); ="é">"f" TRUE (Calc FALSE, locale order); " 5 "+0, "TRUE"+0, "$5"+0, "1,000"+0, "50%"+0 give #VALUE! (Calc 5, 1, 5, 1000, 0.5) (G21, G26, G27). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

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
| not yet | b1 | text comparison with = <> < > matches LibreOffice's default (case-sensitive, locale collation) on a set of cases computed by LibreOffice | no landed check |
| not yet | b2 | text-to-number coercion in arithmetic matches LibreOffice for padded, boolean, currency, thousands-separated and percent text, computed by LibreOffice | no landed check |

## 5. Out of scope and risks

- **Out of scope:** dates and date text
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/values/**`, `exp-a:src/eval/**`, `exp-a:tests/values/**`, `exp-a:tests/eval/**`

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
