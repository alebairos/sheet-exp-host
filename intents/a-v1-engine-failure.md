# Intent `a-v1-engine-failure`

## 1. Outcome

> One formula the engine can't handle breaks the whole workbook. Observed: a 1000-term =1+1+...+1 hits a Python RecursionError: the CLI prints a traceback and no output for any cell, and in the browser serve.py drops the connection, every later edit shows "Could not compute: Failed to fetch" and the UI stays frozen (G18, G28 deep-formula part). Expected: that cell gets an error value, every other cell computes, and the page keeps working. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: accepted · 2 work items · 2 bullets

## 2. What you will see

A very long formula no longer breaks the workbook. A 1000-term =1+1+...+1 gives 1000 in ./engine and in the browser, as in LibreOffice Calc. A formula past Calc's limit (more than 8192 tokens, e.g. a 5000-term sum) shows Calc's Err:512 in its own cell, and cells reading it show Err:512 too, while every other cell computes normally. In the browser you can keep editing afterwards. If the engine ever fails, the page says 'Could not compute: the server answered 500' and the server keeps running, instead of dropping the connection and freezing.

- [a-v1-engine-failure/README.md](https://github.com/alebairos/sheet-exp-host/blob/5a8a0fbf6c8c5dfcd53f8202684f7bf7c3760a2d/a-v1-engine-failure/README.md)
- [a-v1-engine-failure/today-checks.txt](https://github.com/alebairos/sheet-exp-host/blob/5a8a0fbf6c8c5dfcd53f8202684f7bf7c3760a2d/a-v1-engine-failure/today-checks.txt)
- [a-v1-engine-failure/prototype-checks.txt](https://github.com/alebairos/sheet-exp-host/blob/5a8a0fbf6c8c5dfcd53f8202684f7bf7c3760a2d/a-v1-engine-failure/prototype-checks.txt)
- [a-v1-engine-failure/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/5a8a0fbf6c8c5dfcd53f8202684f7bf7c3760a2d/a-v1-engine-failure/prototype.diff)

## 3. Approach

Cause, as read in the code and run on main. The parser builds =1+1+...+1 with a loop as a left-deep tree. src/eval's _eval then walks that tree recursively, and at about 1000 terms Python's recursion limit raises RecursionError. That error escapes recalc and the CLI, so the whole workbook is lost. In the browser, web/io/serve.py does not catch it, so the connection drops ('Failed to fetch'), and the bad formula stays in the book, so every later compute fails too (G18). Calc also has a limit of its own: past 8192 tokens a formula is Err:512 (formula overflow).
Fix (WI 1, about 25 lines, as in the evidence prototype). _eval walks a Binary node's left spine with a loop and folds left to right (Calc's order), so the length of a chain no longer matters. parse() returns an Err:512 error node for a formula of more than 8192 tokens, counted after a successful parse, so a-i1's 'deep nesting is a ParseError' test still holds; =B1+B2 then propagates Err:512 as Calc does. serve.py catches an exception from compute and answers 500 with 'could not compute: <reason>', then keeps serving. The page already shows 'Could not compute: ...' for a non-200 answer. WI 2 adds tests/eval/test_long_formulas.py.

Beliefs:
- ran: on main a 900-term sum computes and a 1000-term one raises RecursionError (no output, exit 1). serve.py drops the connection when compute raises. In the browser a 1000-term formula leaves the cell empty. Settled by a_v1_ef_b1_long.sh, a_v1_ef_b2_serve.sh and a_v1_ef_b2_page.sh, all red on main (evidence today-checks.txt).
- ran: LibreOffice Calc 26.8.1.1 headless (a_v1_ef_probe.py, read from a_v1_ef_calc.json): the 1000-term sum is 1000; the 4095- and 4096-term sums compute; the 4097- and 5000-term sums are Err:512, and so is =B1+B2 that reads one; the 1000-term sum of A1 is 2000; the 2000-term chain A1-A1-... is -3996; after A1 := 7, A2 =A1*3 is 21 and C1 =SUM(A1:A2) is 28. Settled by b1 and b2.
- memory: Calc's limit is on tokens (FORMULA_MAXTOKENS 8192), not characters. ran: 4096 terms (8191 tokens) compute and 4097 terms (8193) do not, which fits. Settled by b1's 4096/4097 pair.
- ran: on the prototype (src/eval, src/parser, serve.py, +23 -5) all three checks, the suite check with a stand-in test, ./test.sh (75 tests, including a-i1's deep-nesting ParseError) and every earlier check script pass. Settled by the land test.
- code: deep nesting (5000 parentheses) is still recursive in the parser and is a ParseError, so the cell is #VALUE! as before. Calc's answer for that is not claimed here. Settled by: not claimed (a-v1-parse-fidelity owns parse errors).

Learned from RECORD.md and the overlapping pages: a-i4 rejected recursive on-demand evaluation because it 'overflows on a 10,000-cell chain' and made recalc iterative. This finishes the job inside one formula. a-i3's reviewer asked to catch a function's Python exception; here the server catches what escapes, so the page keeps working, while the cell-level fix makes the engine itself not fail. Calc's own error names are kept (Err:512, like a-i4's Err:522). Values come from running Calc, including the 8192-token edge, which the review did not probe. Overlap: a-v1-cli-input claims the CLI's other input errors and leaves this crash to this intent. a-v1-decimal-noise and a-v1-eval-edges also touch src/eval (operators and edge cases), and a-v1-parse-fidelity touches the parser. Whichever lands later carries both.

- **Reuses:** The parser's loop-built left-deep trees, src/eval's _binary and _scalar, the error-node path (p.Error) and Calc's Err:NNN names, the page's existing 'Could not compute' message, and http.server's send_error.
- **Removes:** The recursion over binary chains in src/eval, and the dropped connection on a compute failure in serve.py.
- **Rejected:** Raising Python's recursion limit: it only moves the crash and can overflow the C stack. Rewriting the whole evaluator as a stack machine: more change than the failure needs, since only binary chains get long in practice (function arguments and nesting are bounded by the 8192-token limit). A character limit instead of tokens: Calc's limit is on tokens, as the 4096/4097 probe shows. Catching every exception per cell and turning it into #VALUE!: it would hide engine bugs, and Calc's answer here is a value or Err:512.

## 4. Work items

### `wi-a-v1-engine-failure-1`: Long formulas compute; failures don't freeze

src/eval folds long operator chains with a loop instead of recursion, the parser gives Calc's Err:512 past 8192 tokens, and serve.py answers a failing compute with an HTTP error and keeps serving, so one long formula no longer breaks the workbook or the page.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ef-b1` | b1 | `tests/eval/checks/a_v1_ef_b1_long.sh` | red | — |
| `ac-ef-b2-serve` | b2 | `tests/web/io/checks/a_v1_ef_b2_serve.sh` | red | — |
| `ac-ef-b2-page` | b2 | `tests/e2e/ui/checks/a_v1_ef_b2_page.sh` | red | — |

### `wi-a-v1-engine-failure-2`: Product tests for long formulas

Adds tests/eval/test_long_formulas.py, run by ./test.sh, covering 1000- and 4096-term sums, Err:512 past 8192 tokens with the rest of the workbook computing, and serve.py's error answer, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-engine-failure-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ef-suite` | b1, b2 | `tests/eval/checks/a_v1_ef_suite.sh` | red | — |
| `ac-ef-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through ./engine and the app page as shipped, if an ordinary user pastes a very long formula (say a 1000-term sum, and one far longer) into a workbook and then keeps working, do the rest of their cells keep computing and does the page keep responding, with an understandable result or message for the long formula instead of a crash or a frozen page? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | a workbook with a 1000-term and a 5000-term sum formula computes through ./engine: those cells give Calc's value (or an error value if Calc gives one) and every other cell computes as before | no landed check |
| not yet | b2 | in the browser, entering such a formula and then editing another cell keeps computing, and an engine failure shows a message without freezing the page | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other CLI input errors
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/parser/**`, `exp-a:src/eval/**`, `exp-a:src/recalc/**`, `exp-a:web/io/serve.py`, `exp-a:tests/eval/**`, `exp-a:tests/recalc/**`, `exp-a:tests/parser/**`, `exp-a:tests/web/io/**`, `exp-a:tests/e2e/ui/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-engine-failure-1` | — |
| Reviewed `wi-a-v1-engine-failure-1` | — |
| Implemented `wi-a-v1-engine-failure-2` | — |
| Reviewed `wi-a-v1-engine-failure-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 11 h 01 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
