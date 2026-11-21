# Intent `a-v1-start-docs`

## 1. Outcome

> A new user can't find how to start the browser UI, and part of the tests never run. Observed: README.md documents only ./test.sh and ./engine; the UI's start (python3 web/io/serve.py, then /io/index.html) is only in web/io/README.md, and web/grid/README.md points to a demo with no engine; the grid's Node tests (tests/web/grid) are not run by ./test.sh (G31, G32; prior S1, T1). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Standard · State: parked · 0 work items · 2 bullets

## 2. What you will see

No design in the plan.

## 3. Approach

No design in the plan.

## 4. Work items

No plan yet.

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | README.md tells a new user how to start the browser UI and which URL to open, and following it from a clean clone shows the app page | no landed check |
| not yet | b2 | ./test.sh runs the web parts' Node tests and fails when one fails | no landed check |

## 5. Out of scope and risks

- **Out of scope:** changing the tests' content
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:README.md`, `exp-a:web/grid/README.md`, `exp-a:test.sh`, `exp-a:tests/web/**`

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
