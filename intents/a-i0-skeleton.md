# Intent `a-i0-skeleton`

## 1. Outcome

> The engine CLI exists and builds and tests from a clean clone with ./test.sh: it reads a workbook JSON (SPEC.md) and prints it back with constants unchanged, and the repo has one directory per part (src/parser, src/values, src/eval, src/recalc, src/functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e) with a way to register functions that needs no shared file edits

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
| not yet | b1 | `engine -` prints a workbook of constants unchanged, in SPEC.md's output shape | no landed check |
| not yet | b2 | `engine - --cell Sheet1!A1` prints one value | no landed check |
| not yet | b3 | ./test.sh builds and runs every test from a clean clone | no landed check |

## 5. Out of scope and risks

- **Out of scope:** formulas; functions; the UI
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:/**`

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
