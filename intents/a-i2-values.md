# Intent `a-i2-values`

## 1. Outcome

> Cell values and coercion behave as in Calc: numbers, text, booleans, blanks and the six errors, with text-to-number, boolean-as-1/0 and blank-as-0-or-empty

Kind: Feature · State: awaiting the verdict · 1 work item · 2 bullets

## 2. What you will see

A Python module src/values that every later part uses: from_json/to_json turn a workbook cell (1, "text", true, null, {"error": "#DIV/0!"}) into a value and back unchanged, with an integral number written as an integer (2.0 shows 2); to_number, to_text and compare apply Calc's rules: "12"+1 is 13, "abc"+1 and ""+1 are #VALUE!, TRUE counts as 1, a blank cell is 0 in arithmetic and "" in text, 0.1+0.2 joined as text is "0.3", text sorts after every number and compares case-insensitively, TRUE=1 is true (booleans are numbers in Calc). The ./engine output does not change: it already echoes every constant, and the check keeps it that way.

- No media: A library module with no screen; its sample inputs and outputs are the cases in tests/values/checks/a2_*.sh

## 3. Approach

Value kinds first, because the evaluator (a-i3) and every function intent build on them. Immutable value classes: Number(float), Text(str), Bool, the BLANK singleton and Error(code) for #DIV/0! #VALUE! #REF! #NAME? #N/A #NUM!. from_json/to_json map JSON cells both ways (a non-finite number goes out as #NUM!). to_number: Number as is; Bool 1/0; BLANK 0; Text converts only if unambiguous (Calc's default): an optionally signed decimal with optional exponent, else #VALUE!, and the empty string is #VALUE!; an Error passes through. to_text: Calc's general format with 15 significant digits (1 not 1.0, 0.1+0.2 as 0.3, large and small numbers as 1E+20), TRUE/FALSE, BLANK as "". compare(a, b) returns -1/0/1 or the first operand's error: a blank takes the other side's kind (0 or ""); booleans compare as numbers; any number is below any text; text compares case-insensitively. Unit tests in tests/values (with __init__.py so ./test.sh finds them); the two plan checks in tests/values/checks are the contract.

- **Reuses:** The part directory src/values and the ./test.sh suite from a-i0-skeleton; SPEC.md's output shape for numbers, text, booleans and errors; the ./engine CLI, which already echoes constants.
- **Removes:** none
- **Rejected:** Excel's rules (booleans distinct from numbers in comparisons, empty text as 0): Calc is the judge. Converting any text Python's float() accepts (" 12", "inf", "1_000"): Calc's default rejects ambiguous text. Wiring values into src/cli.py now: cli.py is outside this intent's scope, and the CLI already round-trips every kind; the evaluator wires values in when formulas are computed.

## 4. Work items

### `wi-a-i2-values-1`: Cell values and Calc coercion

Add src/values: the five kinds of cell value (number, text, boolean, blank, error) with conversion to and from the workbook JSON, and Calc's coercions for arithmetic, concatenation and comparison, so the evaluator and functions share one set of rules.

Status: landed (`50e142fa3f8f`)

**The passing review noted:** > PASS. Verify rerun in a worktree of 23423c5: both checks green (ok b1, ok b2), ./test.sh 25 tests OK; on plan base 6a8a8fa both red (ImportError: from_json). No check file edited; the 3 paths are inside src/values and tests/values.
> ac-a2-b1 (tests/values/checks/a2_b1_roundtrip.sh): from_json src/values/__init__.py:130-144 (null->BLANK, bool before int, {"error":..}->Error), to_json :147-164 (integral finite floats below 2^53 as int, non-finite as #NUM!); value classes immutable and hashable :21-121. The CLI part of the check passes on ./engine unchanged, as the design says.
> ac-a2-b2 (tests/values/checks/a2_b2_coercion.sh): to_number :171-189 (unambiguous signed decimal/exponent only; "" and "TRUE" -> #VALUE!; Bool 1/0; BLANK 0; errors pass); to_text + format_number :192-223 (15 significant digits, 1E+15 / 1E-05 style, 0.1+0.2 -> "0.3"); compare :239-267 (error of first operand first, blank takes the other side's kind, numbers/booleans rank below text, casefold for text).
> Notes, not blocking: from_json accepts any error string (e.g. {"error":"#FOO"}) without checking ERROR_CODES, and turns lists/other dicts into #VALUE! silently; text ordering is casefold codepoint order, not Calc's locale collation (matters only for punctuation/accents, later intents may need it for sort/MATCH). -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a2-b1` | b1 | `tests/values/checks/a2_b1_roundtrip.sh` | red | — |
| `ac-a2-b2` | b2 | `tests/values/checks/a2_b2_coercion.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | each value kind round-trips through the CLI | `tests/values/checks/a2_b1_roundtrip.sh` — |
| not yet | b2 | coercion between kinds matches Calc for arithmetic and comparison | `tests/values/checks/a2_b2_coercion.sh` — |

## 5. Out of scope and risks

- **Out of scope:** formulas; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/values/**`, `exp-a:tests/values/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i2-values-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-i2-values-1` | `rev-a@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-i2-values-1`:

- `src/values/__init__.py` +267 −1
- `tests/values/test_values.py` +107 −0 (test)
- `tests/values/checks/a2_b1_roundtrip.sh` +49 −0 (plan check)
- `tests/values/checks/a2_b2_coercion.sh` +46 −0 (plan check)
- `tests/values/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #4](https://github.com/alebairos/sheet-exp-a/pull/4)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 8 h 24 min so far
- Loops: 0
- Waste: 0 min
- Size: 268 lines (+267 −1, 3 files, ≤400; tests 107 lines); plan check files laid over by land, not in the size: +95 −0, 2 files
