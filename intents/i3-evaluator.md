# Intent `i3-evaluator`

## 1. Outcome

> A parsed formula evaluates with Calc's operators and error propagation (#DIV/0!, #VALUE!, #REF!, #NAME?)

Kind: Feature · State: in work · 1 work item · 3 bullets

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

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/eval/checks/b1_operators.sh` | red | — |
| `ac-b2` | b2 | `tests/eval/checks/b2_errors.sh` | red | — |
| `ac-b3` | b3 | `tests/eval/checks/b3_names.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | arithmetic, comparison, & and % match Calc | no landed check |
| not yet | b2 | errors propagate through operators as in Calc | no landed check |
| not yet | b3 | an unknown function is #NAME? | no landed check |

## 5. Out of scope and risks

- **Out of scope:** functions; recalculation order; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/eval/**`, `exp-b:tests/eval/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i3-evaluator-1` | — |
| Reviewed `wi-i3-evaluator-1` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 22 h 47 min so far
- Loops: 4 (D1 spec 1, D2 plan 3)
- Waste: 3 h 33 min
- Size: nothing landed yet
