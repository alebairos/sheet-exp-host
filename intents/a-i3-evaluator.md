# Intent `a-i3-evaluator`

## 1. Outcome

> A parsed formula evaluates with Calc's operators and error propagation (#DIV/0!, #VALUE!, #REF!, #NAME?)

Kind: Feature · State: awaiting the verdict · 1 work item · 3 bullets

## 2. What you will see

A formula now has a value, computed as Calc computes it: =10/4 is 2.5, =2^3^2 is 64, =-2^2 is 4, =50% is 0.5, ="3"*2 is 6, =TRUE+1 is 2, a blank cell is 0 (=Z99+1 is 1) or "" (=Z99&"x" is "x"), ="b">"a" is TRUE, =1&TRUE is "11" (Calc joins TRUE as 1), =10<"9" is TRUE (numbers sort before text), =0.1+0.2&"" is "0.3". Errors flow through as Calc's: =1/0 is #DIV/0!, ="abc"+1 is #VALUE!, a cell holding #N/A makes =A1+1 #N/A, a reference to a sheet the workbook does not have is #REF! (=NoSuchSheet!A1, =NoSuchSheet!A1+1, =1+NoSuchSheet!A1:A2) as is a cell holding #REF! (=B3+1), a range of several cells in an operator (=A1:A2+1) is #VALUE!, and an unknown function or name (=FOO(1), =foo) is #NAME?. The function intents plug in by registering a function: the evaluator calls it with the values of its arguments. ./engine output does not change yet: putting values in the CLI's cells is recalculation's job (a-i4).

- No media: A library module with no screen; its sample formulas and values are the cases in tests/eval/checks/a3_*.sh

## 3. Approach

The operator core first, as one module src/eval built on the two parts it depends on: the parser's tree (a-i1) and the values with their coercions (a-i2). evaluate(formula, book, sheet) parses the cell text, walks the tree and returns a src.values Value; book is SPEC.md's workbook JSON and sheet the formula's own. Literals become values; a reference or range becomes a Range (sheet plus corners over the book, values() row by row with blanks, an unknown sheet gives #REF!); in operator context a Range collapses to its single cell's value (more than one cell is #VALUE!, since Calc's implicit intersection needs a cell position the evaluator does not have). Arithmetic + - * / ^ goes through to_number; & first turns a boolean operand into its number (TRUE is 1, FALSE is 0, as Calc stores them) and then goes through to_text, so =1&TRUE is "11" and a TRUE cell &"x" is "1x" as LibreOffice gives (checked headless); this happens in src/eval, so src.values.to_text (a-i2's, outside this scope) is unchanged; comparisons through compare (whether text compares case-sensitively is a document setting in Calc, on by default and off for xlsx files, so no check pins ="a"="A"; compare is left as a-i2 wrote it), unary minus and % through to_number; any error operand gives that error, x/0 is #DIV/0!. A name that is not a function call is #NAME?; a call looks its name up in src.functions.registry() at evaluation time (so functions registered later are found) and an unknown one is #NAME? without evaluating its arguments' effects. Calling convention, pinned by the b3 check: positional arguments; a reference or range argument arrives as a Range (so ISBLANK, COUNTA and SUMIF see blanks and text), every other argument as a Value with errors left in (IFERROR and ISERROR need them), an omitted argument as the blank value; the function returns a Value (or a Range, collapsed like a reference). The final result of a lone blank reference is 0, as Calc shows =A1 on an empty cell; a formula that does not parse evaluates to an error value, never an exception. Referenced formula cells are read as they stand in the book: computing them first is a-i4's dependency order. Unit tests in tests/eval (with __init__.py so ./test.sh finds them); the plan checks in tests/eval/checks are the contract, each with its fixture inlined (no shared helper file); a3_b2 pins #REF! for unknown sheets (alone, in arithmetic, as a range operand) and from a cell holding #REF!, and #VALUE! for a multi-cell range in an operator.

- **Reuses:** src/parser's parse and tree (a-i1-parser) and src/values' Value kinds, to_number, to_text and compare (a-i2-values), so the coercion rules live in one place; src.functions.register and registry() from a-i0-skeleton for calls.
- **Removes:** none
- **Rejected:** Evaluating by translating formulas to Python and calling eval(): unsafe on untrusted workbooks and no control over Calc's coercions. Raising Python exceptions for spreadsheet errors: errors are ordinary values in Calc (IFERROR, ISERROR take them), so they flow as values and nothing is caught by accident. Expanding ranges into plain lists before the call: functions could no longer tell a blank from an empty text or a range from an array of values, which SUMIF, COUNTA and ISBLANK need. Implicit intersection for multi-cell ranges in operators now: it needs the formula cell's position, which arrives with recalculation.

## 4. Work items

### `wi-a-i3-evaluator-1`: Evaluate formulas: operators, errors, calls

Add src/eval: walk the parser's tree over a workbook and compute it with Calc's operators, coercion and error propagation (#DIV/0!, #VALUE!, #REF!, #N/A), return #NAME? for an unknown function or name, and call registered functions with one agreed argument shape, so formulas produce values and the function intents have something to plug into.

Status: landed (`99c5a4e22d9a`)

**The passing review noted:** > PASS.
> 
> Verify rerun on 6442703 (host wi/wi-a-i3-evaluator-1): a3_b1_operators "ok b1", a3_b2_errors "ok b2", a3_b3_names "ok b3 / ok b3 calling convention". All three are red on the plan commit 3a16c9c (ImportError: no evaluate in src.eval). ./test.sh: 53 tests OK, including tests/eval/test_eval.py. The WI does not touch any check file. Every path is inside exp-a:src/eval/** and exp-a:tests/eval/**.
> 
> Per AC:
> - ac-a3-b1 (b1, operators match Calc): met. Arithmetic goes through to_number with leftmost-error-wins (src/eval/__init__.py:166-173). Division by 0 gives #DIV/0! (:148). Powers follow LibreOffice: 0^0=1, 0^-1=#NUM!, an odd root of a negative base (:121-137). & turns booleans into 1/0 before to_text (:152-156, :174-180). Comparisons go through a-i2's compare (:181-183); unary minus and % through to_number (:221-226). Lone blank shows 0 (:237).
> - ac-a3-b2 (b2, errors propagate): met. Error operands pass through each operator (:169-172, :176-179, compare). An unknown sheet gives #REF! (:103-109), a cell holding #REF! passes it on, and a multi-cell range in operator context gives #VALUE! (:79-83).
> - ac-a3-b3 (b3, unknown function is #NAME?): met. A bare name gives #NAME? (:215-216). An unknown call returns #NAME? before evaluating its arguments (:187-190). The calling convention matches the plan: a Range for references, a Value with errors kept otherwise, BLANK for an omitted argument (:191-200).
> 
> Spot checks I ran beyond the checks: =TRUE=1 TRUE, =Z99="" TRUE, =Z99=0 TRUE, =A4<1 with A4 #N/A gives #N/A, =1/0<2 #DIV/0!, =foo(1/0) #NAME?, =2^1024 and =1E308*10 #NUM!, ='Other Sheet'!A1*2 10, =-(-8)^(1/3) 2. All agree with Calc.
> 
> Notes (non-blocking):
> 1. _call calls registry() on every function call node (:188). Today registry() re-runs invalidate_caches() and pkgutil discovery each time (src/functions/__init__.py, a-i0's). On large workbooks that is a filesystem walk per call; a-i4's speed measurement may want registry() cached after the first discovery.
> 2. A registered function that raises a Python exception propagates out of evaluate(). Only parse failures are turned into error values (:242-245). Worth catching once functions land, so one bad function cannot crash ./engine.
> 3. A literal that overflows (=1E400) and a range across two sheets (=Sheet1!A1:Other!A2) both give #VALUE! as parse failures. Calc reports these differently (Err:504/#REF!). These are edge cases owned by the parser.
> 
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a3-b1` | b1 | `tests/eval/checks/a3_b1_operators.sh` | red | — |
| `ac-a3-b2` | b2 | `tests/eval/checks/a3_b2_errors.sh` | red | — |
| `ac-a3-b3` | b3 | `tests/eval/checks/a3_b3_names.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | arithmetic, comparison, & and % match Calc | `tests/eval/checks/a3_b1_operators.sh` — |
| not yet | b2 | errors propagate through operators as in Calc | `tests/eval/checks/a3_b2_errors.sh` — |
| not yet | b3 | an unknown function is #NAME? | `tests/eval/checks/a3_b3_names.sh` — |

## 5. Out of scope and risks

- **Out of scope:** functions; recalculation order; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/eval/**`, `exp-a:tests/eval/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i3-evaluator-1` | `impl-a1@alebairos` |
| Reviewed `wi-a-i3-evaluator-1` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-i3-evaluator-1`:

- `src/eval/__init__.py` +246 −1
- `tests/eval/test_eval.py` +123 −0 (test)
- `tests/eval/checks/a3_b3_names.sh` +84 −0 (plan check)
- `tests/eval/checks/a3_b2_errors.sh` +59 −0 (plan check)
- `tests/eval/checks/a3_b1_operators.sh` +56 −0 (plan check)
- `tests/eval/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #8](https://github.com/alebairos/sheet-exp-a/pull/8)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 20 h 36 min so far
- Loops: 4 (D1 spec 1, D2 plan 3)
- Waste: 3 h 42 min
- Size: 247 lines (+246 −1, 3 files, ≤400; tests 123 lines); plan check files laid over by land, not in the size: +199 −0, 3 files
