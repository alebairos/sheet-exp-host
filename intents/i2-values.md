# Intent `i2-values`

## 1. Outcome

> Cell values and coercion behave as in Calc: numbers, text, booleans, blanks and the six errors, with text-to-number, boolean-as-1/0 and blank-as-0-or-empty

Kind: Feature · State: Met · 1 work item · 2 bullets

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

Status: landed (`ff20d95fb5f8`)

**The passing review noted:** > pass wi-i2-values-1 attempt 2 (same commit 5f0d7817d3246c2f5ce29e40c1aaf8a28966446e)
> 
> land: attempt 1 aborted after tests green: host rejected push of land/wi-i2-values-1 (f1804b7b…); LandAborted head mismatch. Not a verify failure. Re-ran checks.
> 
> ac-b1: tests/values/checks/b1_roundtrip.sh exit 0; from_json/to_json src/values/__init__.py:128-162
> ac-b2: tests/values/checks/b2_coercion.sh exit 0; to_number:169-184 to_text:187-218 compare:243-262
> ./test.sh exit 0
> scope: exp-b:src/values/** and exp-b:tests/values/** only; plan checks under tests/values belong; law 9 drops them at land.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/values/checks/b1_roundtrip.sh` | red | pass |
| `ac-b2` | b2 | `tests/values/checks/b2_coercion.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | each value kind round-trips through the CLI | `tests/values/checks/b1_roundtrip.sh` pass |
| PASS | b2 | coercion between kinds matches Calc for arithmetic and comparison | `tests/values/checks/b2_coercion.sh` pass |

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
| Reviewed `wi-i2-values-1` | `rev-1@alebairos` (passed attempt 2) |
| Verdict (Met) | `alebairos` |

Product checks:

- `tests/values/checks/b1_roundtrip.sh`: pass
- `tests/values/checks/b2_coercion.sh`: pass

Outcome report:

- **Built:** Intent i2-values: Cell values and coercion behave as in Calc: numbers, text, booleans, blanks and the six errors, with text-to-number, boolean-as-1/0 and blank-as-0-or-empty. i2-values · Feature /   parked ✓ ─ planned ✓ ─ certified ✓ ─ accepted ✓ ─ admitted ✓ ─ landing ✓ ─ verdict ◐ /   wi-i2-values-1  landed · 1/3 attempts failed · reviewed ✓
- **Advice:** Adopt. HITL verdict is next.
- No media: A library module with no screen; its sample inputs and outputs are the cases in tests/values/checks/b*.sh

Files landed by `wi-i2-values-1`:

- `src/values/__init__.py` +262 −0
- `tests/values/test_values.py` +93 −0 (test)
- `tests/values/checks/b1_roundtrip.sh` +49 −0 (plan check)
- `tests/values/checks/b2_coercion.sh` +46 −0 (plan check)
- `tests/values/__init__.py` +1 −0 (plan check)

Landing pull request: [exp-b #5](https://github.com/alebairos/sheet-exp-b/pull/5)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 10 h 22 min
- Loops: 1 (D6 landing 1)
- Waste: 11 min
- Size: 262 lines (+262 −0, 2 files, ≤400; tests 93 lines); plan check files laid over by land, not in the size: +96 −0, 3 files
