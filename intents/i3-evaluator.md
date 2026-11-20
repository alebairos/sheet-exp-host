# Intent `i3-evaluator`

## 1. Outcome

> A parsed formula evaluates with Calc's operators and error propagation (#DIV/0!, #VALUE!, #REF!, #NAME?)

Kind: Feature · State: awaiting the verdict · 1 work item · 3 bullets

## 2. What you will see

A formula now has a value, computed as Calc computes it: =10/4 is 2.5, =2^3^2 is 64, =-2^2 is 4, =50% is 0.5, ="3"*2 is 6, =TRUE+1 is 2, a blank cell is 0 (=Z99+1 is 1) or "" (=Z99&"x" is "x"), ="a"="A" is TRUE, =10<"9" is TRUE (numbers sort before text), =0.1+0.2&"" is "0.3". Errors flow through as Calc's: =1/0 is #DIV/0!, ="abc"+1 is #VALUE!, =NoSuchSheet!A1 is #REF!, a cell holding #N/A or #REF! makes =A1+1 that error, and an unknown function or name (=FOO(1), =foo) is #NAME?. Function intents plug in by registering on src.eval: the evaluator calls the function with the values of its arguments. ./engine output does not change yet: putting values in the CLI's cells is recalculation's job (i4).

- No media: A library module with no screen; its sample formulas and values are the cases in tests/eval/checks/b*.sh

## 3. Approach

The operator core first, as one module src/eval built on the parser's tree (i1) and the values with their coercions (i2). evaluate(formula, book, sheet) parses the cell text, walks the tree and returns a src.values Value; book is SPEC.md's workbook JSON and sheet the formula's own. Literals become values; a reference or range becomes a Range (sheet plus corners over the book, values() row by row with blanks, an unknown sheet gives #REF!); in operator context a Range collapses to its single cell's value (more than one cell is #VALUE!, since Calc's implicit intersection needs a cell position the evaluator does not have). Arithmetic + - * / ^ goes through to_number, & through to_text, comparisons through compare, unary minus and % through to_number; any error operand gives that error, x/0 is #DIV/0!. A name that is not a function call is #NAME?; a call looks its name up in src.eval.registry() at evaluation time (so functions registered later are found) and an unknown one is #NAME? without evaluating its arguments' effects. src.eval.register(name, fn) and registry() live in this intent's scope: registry() merges what was registered directly with each package's uppercase-keyed FUNCTIONS dict (name → callable) from i0's real src.functions.registry.discover_functions(), looked up at call time. Calling convention, pinned by the b3 check (which imports from src.eval import register): positional arguments; a reference or range argument arrives as a Range (so ISBLANK, COUNTA and SUMIF see blanks and text), every other argument as a Value with errors left in (IFERROR and ISERROR need them), an omitted argument as the blank value; the function returns a Value (or a Range, collapsed like a reference). The final result of a lone blank reference is 0, as Calc shows =A1 on an empty cell; a formula that does not parse evaluates to an error value, never an exception. Referenced formula cells are read as they stand in the book: computing them first is i4's dependency order. Unit tests in tests/eval (with __init__.py so ./test.sh finds them); the plan checks in tests/eval/checks are the contract. b2 covers #REF! for a missing sheet (=NoSuchSheet!A1 and through operators) and a stored #REF! cell (B3) flowing through + * & =.

- **Reuses:** src/parser's parse and tree (i1-parser) and src/values' Value kinds, to_number, to_text and compare (i2-values), so the coercion rules live in one place; i0's src.functions.registry.discover_functions() to find each package's FUNCTIONS dict, merged by src.eval.registry() at call time.
- **Removes:** none
- **Rejected:** Evaluating by translating formulas to Python and calling eval(): unsafe on untrusted workbooks and no control over Calc's coercions. Raising Python exceptions for spreadsheet errors: errors are ordinary values in Calc (IFERROR, ISERROR take them), so they flow as values and nothing is caught by accident. Keeping register/registry in src/functions: the HITL clarification put them in src/eval so this intent's scope owns the call table while still discovering package FUNCTIONS via i0. Expanding ranges into plain lists before the call: functions could no longer tell a blank from an empty text or a range from an array of values, which SUMIF, COUNTA and ISBLANK need. Implicit intersection for multi-cell ranges in operators now: it needs the formula cell's position, which arrives with recalculation.

## 4. Work items

### `wi-i3-evaluator-1`: Calc formula evaluator

Add src.eval.evaluate with Calc operators, error propagation including #REF!, #NAME? for unknown calls, and register/registry in src/eval, proven by the three plan checks.

Status: landed (`aa4b68601c18`)

**The passing review noted:** > pass review of wi-i3-evaluator-1 @ 1201b7a (attempt 1).
> 
> verify (detached worktree at WI commit): b1_operators.sh EXIT 0 (ok b1); b2_errors.sh EXIT 0 (ok b2); b3_names.sh EXIT 0 (ok b3 + ok b3 calling convention); ./test.sh EXIT 0.
> 
> ac-b1 / b1 (arithmetic, comparison, & and % match Calc): check tests/eval/checks/b1_operators.sh green. Diff implements operators via _binary/_on_number using to_number/to_text/compare at src/eval/__init__.py:179-206; % and unary minus at :154-157; ^ and / via _pow/_div at :220-236. Covered by unit cases in tests/eval/test_eval.py.
> 
> ac-b2 / b2 (errors propagate through operators): check tests/eval/checks/b2_errors.sh green. Error operands short-circuit in _binary (:185-204); x/0 → DIV0 in _div (:220-223); missing sheet → REF via Range.values/_cell (:94-108,:279-286). Matches design's #REF!/#DIV/0!/#VALUE! flow.
> 
> ac-b3 / b3 (unknown function is #NAME?): check tests/eval/checks/b3_names.sh green and imports from src.eval import register (clarification satisfied; prior rejection about src.functions.register is fixed in the certified check). register/registry at :59-79 merge discover_functions FUNCTIONS with _REGISTERED; unknown Call returns NAME before arg eval at _call :160-165; bare Name → NAME at :149-150.
> 
> scope: last_diff only src/eval/__init__.py and tests/eval/test_eval.py under path_scope; outside_scope null. No findings blocking land.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/eval/checks/b1_operators.sh` | red | — |
| `ac-b2` | b2 | `tests/eval/checks/b2_errors.sh` | red | — |
| `ac-b3` | b3 | `tests/eval/checks/b3_names.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | arithmetic, comparison, & and % match Calc | `tests/eval/checks/b1_operators.sh` — |
| not yet | b2 | errors propagate through operators as in Calc | `tests/eval/checks/b2_errors.sh` — |
| not yet | b3 | an unknown function is #NAME? | `tests/eval/checks/b3_names.sh` — |

## 5. Out of scope and risks

- **Out of scope:** functions; recalculation order; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/eval/**`, `exp-b:tests/eval/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i3-evaluator-1` | `impl-2@alebairos` |
| Reviewed `wi-i3-evaluator-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-i3-evaluator-1`:

- `src/eval/__init__.py` +300 −0
- `tests/eval/test_eval.py` +144 −0 (test)
- `tests/eval/checks/b3_names.sh` +85 −0 (plan check)
- `tests/eval/checks/b1_operators.sh` +56 −0 (plan check)
- `tests/eval/checks/b2_errors.sh` +56 −0 (plan check)
- `tests/eval/__init__.py` +1 −0 (plan check)

Landing pull request: [exp-b #8](https://github.com/alebairos/sheet-exp-b/pull/8)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 25 h 45 min so far
- Loops: 4 (D1 spec 1, D2 plan 3)
- Waste: 3 h 33 min
- Size: 300 lines (+300 −0, 2 files, ≤400; tests 144 lines); plan check files laid over by land, not in the size: +198 −0, 4 files
