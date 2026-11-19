# Intent `i2-values`

## 1. Outcome

> Cell values and coercion behave as in Calc: numbers, text, booleans, blanks and the six errors, with text-to-number, boolean-as-1/0 and blank-as-0-or-empty

Kind: Feature · State: in work · 1 work item · 2 bullets

## 2. What you will see

A Python module src/values that every later part uses: from_json/to_json turn a workbook cell (1, "text", true, null, {"error": "#DIV/0!"}) into a value and back unchanged, with an integral number written as an integer (2.0 shows 2); to_number, to_text and compare apply Calc's rules: "12"+1 is 13, "abc"+1 and ""+1 are #VALUE!, TRUE counts as 1, a blank cell is 0 in arithmetic and "" in text, 0.1+0.2 joined as text is "0.3", text sorts after every number and compares case-insensitively, TRUE=1 is true (booleans are numbers in Calc). The ./engine output does not change: it already echoes every constant, and the check keeps it that way.

- No media: A library module with no screen; its sample inputs and outputs are the cases in tests/values/checks/b*.sh

## 3. Approach

Value kinds first, because the evaluator (i3) and every function intent build on them. Immutable value classes: Number(float), Text(str), Bool, the BLANK singleton and Error(code) for #DIV/0! #VALUE! #REF! #NAME? #N/A #NUM!. from_json/to_json map JSON cells both ways (a non-finite number goes out as #NUM!). to_number: Number as is; Bool 1/0; BLANK 0; Text converts only if unambiguous (Calc's default): an optionally signed decimal with optional exponent, else #VALUE!, and the empty string is #VALUE!; an Error passes through. to_text: Calc's general format with 15 significant digits (1 not 1.0, 0.1+0.2 as 0.3, large and small numbers as 1E+20), TRUE/FALSE, BLANK as "". compare(a, b) returns -1/0/1 or the first operand's error: a blank takes the other side's kind (0 or ""); booleans compare as numbers; any number is below any text; text compares case-insensitively. Unit tests in tests/values (with __init__.py so ./test.sh finds them); the two plan checks in tests/values/checks are the contract.

- **Reuses:** The part directory src/values and the ./test.sh suite from i0-skeleton; SPEC.md's output shape for numbers, text, booleans and errors; the ./engine CLI, which already echoes constants.
- **Removes:** none
- **Rejected:** Excel's rules (booleans distinct from numbers in comparisons, empty text as 0): Calc is the judge. Converting any text Python's float() accepts (" 12", "inf", "1_000"): Calc's default rejects ambiguous text. Wiring values into src/cli.py now: cli.py is outside this intent's scope, and the CLI already round-trips every kind; the evaluator wires values in when formulas are computed.

## 4. Work items

### `wi-i2-values-1`: Calc value kinds

Add from_json/to_json/to_number/to_text/compare in src/values so kinds and Calc coercion are one shared module, proven by the two plan checks.

Status: in review by `rev-1@alebairos`

**The passing review noted:** > pass wi-i2-values-1 (commit 5f0d7817d3246c2f5ce29e40c1aaf8a28966446e on ancestry plan/i2-values b4792f47)
> 
> ac-b1 (b1: each value kind round-trips through the CLI): PASS
> - reran tests/values/checks/b1_roundtrip.sh on WI tree → exit 0 (ok b1)
> - from_json/to_json: src/values/__init__.py:128-162 (kinds Number/Text/Bool/BLANK/Error; integral JSON int; non-finite → #NUM!)
> - CLI path exercised by the check via ./engine -; blank cell --cell → null
> 
> ac-b2 (b2: coercion matches Calc for arithmetic and comparison): PASS
> - reran tests/values/checks/b2_coercion.sh on WI tree → exit 0 (ok b2)
> - to_number: src/values/__init__.py:169-184 (bool 1/0, blank 0, unambiguous text, empty string #VALUE!, errors pass)
> - to_text/format_number: src/values/__init__.py:187-218 (general 15 sig digits, TRUE/FALSE, blank empty)
> - compare: src/values/__init__.py:243-262 (numbers before text, casefold text, blank equals 0 or empty, errors)
> 
> suite: ./test.sh → all tests passed (exit 0); tests/values/test_values.py covers kinds/coercion
> 
> scope: paths under exp-b:src/values/** and exp-b:tests/values/** only
> - note: WI ancestry includes plan commit b4792f47 adding tests/values/checks/*.sh (byte-identical to plan OID). Belongs under tests/values per design; law 9 drops check-file edits at land.
> - no path outside scope
> 
> findings kept for the intent page: to_bool (src/values/__init__.py:221-231) is extra API beyond the two AC contracts; harmless and unused by the plan checks.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/values/checks/b1_roundtrip.sh` | red | — |
| `ac-b2` | b2 | `tests/values/checks/b2_coercion.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | each value kind round-trips through the CLI | no landed check |
| not yet | b2 | coercion between kinds matches Calc for arithmetic and comparison | no landed check |

## 5. Out of scope and risks

- **Out of scope:** formulas; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/values/**`, `exp-b:tests/values/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i2-values-1` | `impl-1@alebairos`, `impl-2@alebairos` |
| Reviewed `wi-i2-values-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 10 h 08 min so far
- Loops: 1 (D6 landing 1)
- Waste: 11 min
- Size: nothing landed yet
