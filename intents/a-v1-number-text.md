# Intent `a-v1-number-text`

## 1. Outcome

> Numbers turned into text differ from Calc. Observed vs LibreOffice 26.8.1.1: "x"&1E-7 gives x1E-07 (Calc x0.0000001); "x"&1E15 x1E+15 (Calc x1000000000000000); CONCATENATE(1E21) 1E+21 (Calc 1E+021); LEN(123456789012345678) 20 and LEN(1E-20) 5 (Calc 21 and 6). Suggested by a-i6 and never parked (G23). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: in work · 2 work items · 1 bullet

## 2. What you will see

Numbers turned into text read as they do in LibreOffice Calc. ="x"&1E-7 gives x0.0000001 (not x1E-07), ="x"&1E15 gives x1000000000000000, =CONCATENATE(1E21) gives 1E+021, and =LEN(123456789012345678) is 21 (its text is 1.23456789012346E+017), the same in &, CONCATENATE, LEFT and LEN. Plain numbers in cells and in the CLI's output are not affected.

- [a-v1-number-text/README.md](https://github.com/alebairos/sheet-exp-host/blob/c85d06c3d2ad1c8b996ff45625bb0a839f55add8/a-v1-number-text/README.md)
- [a-v1-number-text/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/c85d06c3d2ad1c8b996ff45625bb0a839f55add8/a-v1-number-text/prototype.diff)

## 3. Approach

Cause, as read in src/values and run on main. format_number writes '%.15g' with a 2-digit exponent. Calc's text form of a number differs in three ways. (1) Calc writes decimals down to 1E-14 (0.0000001, 0.00000000000123456789) and up to below 1E15, where Python switches to E at 1E-5 and 1E15. (2) Calc writes an integer below 2**53 exactly, even with 16 digits (1000000000000000, 1234567890123456), but 2**53 and above in E. (3) Calc's E form has a 3-digit exponent (1E+021, 1E-020, 9.00719925474099E+015). It also rounds the 15th digit half away from zero.
Fix (WI 1, about 20 lines in src/values, as in the evidence prototype). format_number: 0 is '0'. An integer below 2**53 is written exactly. Otherwise round to 15 significant digits, half away from zero (decimal.Decimal of repr), and write a decimal when the exponent is -14..14, else mantissa + 'E' + sign + 3-digit exponent, with no trailing zeros. tests/values/test_values.py's test_general_format pinned the old '1E+20'. It is updated to Calc's '1E+020' (the record's a-i6 page already said Calc writes 1E+021). WI 2 adds tests/values/test_number_text.py.

Beliefs:
- ran: on main, 135 of the 220 results differ from Calc (x1E-07, 1E+15, 1E+21, LEN 20 for 123456789012345678, ...). Settled by a_v1_nt_b1_text.sh, red on main.
- ran: LibreOffice Calc 26.8.1.1 headless (a_v1_nt_probe.py, read from a_v1_nt_calc.json) gives the four forms for 54 expressions. The first run had 45. It showed the edges, so 9 more were probed at them: 1E-14 and 1.5E-14 decimal while 9.99999999999999E-15 is E; 2^53-1 and -9007199254740991 exact while 2^53+2 is E; 1E15+0.5 is 1E+015. Settled by b1.
- ran: the prototype (evidence prototype.diff) matches all 220 results. Every earlier check script passes. ./test.sh fails only test_general_format's old 1E+20, which the WI updates. Settled by b1 and the land test.
- code: format_number is used for text conversion (to_text: &, CONCATENATE, LEN, LEFT and the other text functions) and nowhere in the CLI's JSON numbers or the grid's display, so neither changes. Settled by the engine e2e checks staying green.
- memory: the halves at the 15th digit (0.1234567890123455, 123456789012345.5) take Calc's half-away-from-zero after the shortest decimal repr. Settled by b1's half cases; a value whose binary form sits just below a half could still differ, and none of the 54 does.

Learned from RECORD.md and the overlapping pages: a-i6 measured these differences against LibreOffice 26.8.1.1, suggested a Defect on src/values format_number (line 192) and 'never parked' it. This is that Defect. a-i6 rejected a separate formatter in the text functions because it belongs to src/values, and the fix stays there. From the a-v1-entry-display gate review (only tuned cases, a rounding miss on halves), this plan probed Calc at the edges and halves before submitting and recorded which cases came from the second run. Overlap: a-v1-entry-display is the grid's display, not this text form, and stays separate. a-v1-decimal-noise (operators) and a-v1-text-rules (coercion) also touch src/values; whichever lands later carries both.

- **Reuses:** src/values' to_text and format_number entry point (every text function already goes through it), and Python's decimal module.
- **Removes:** The '%.15g' formatting with a 2-digit exponent.
- **Rejected:** Formatting inside each text function: a-i6 rejected it, since the conversion belongs to src/values. '%.16g' or repr: Calc writes 15 significant digits except for exact integers below 2**53. Python's round(): it rounds halves to even, Calc away from zero. Changing the grid's or CLI's number output: other intents (a-v1-entry-display, a-v1-decimal-noise).

## 4. Work items

### `wi-a-v1-number-text-1`: Calc's number-to-text form

src/values' format_number writes numbers as Calc turns them into text: decimals from 1E-14 to below 1E15, exact integers below 2^53, 15 digits rounded half away from zero, and E with a 3-digit exponent otherwise, so &, CONCATENATE, LEN and the text functions match LibreOffice.

Status: landed (`1f715b03add3`)

**The passing review noted:** > PASS. Reviewed attempt 2 (7f5df85, on attempt 1 1300f55, base main f101426) with the plan's checks (d4364ad).
> 
> - ac-nt-b1 (tests/values/checks/a_v1_nt_b1_text.sh): "ok b1: 220 number-to-text results match LibreOffice". Red on main (135 FAIL), as checked on attempt 1.
> - ./test.sh: 76 tests OK. That is the 75 before plus the new test_rounding_carry_keeps_the_form.
> - Attempt-1 finding fixed. src/values/__init__.py:207 chooses decimal or E from d.adjusted() (the number before rounding). The E exponent still comes from the rounded q (line 206), so 9.999999999999995E20 stays 1E+021.
> - The carry cases are pinned in tests/values/test_values.py:63-72. Their expected values come from my LibreOffice 26.8 runs.
> - Held-out probe, rerun now against LibreOffice 26.8 (the plan's UNO probe on my own numbers): 57 numbers, 228 results. All match except the DBL_MAX pair (1.7976931348623157E308 and ...155E308): Calc writes 17 digits, the engine 15. That was optional in my attempt-1 review and I leave it as a note.
> - Scope: src/values/__init__.py and tests/values/test_values.py, both in scope. ac-nt-suite (tests/values/test_number_text.py) and the judge belong to WI-2.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-nt-b1` | b1 | `tests/values/checks/a_v1_nt_b1_text.sh` | red | — |

### `wi-a-v1-number-text-2`: Product tests for number-to-text

Adds tests/values/test_number_text.py, run by ./test.sh, covering the decimal/E edges, exact integers, halves and the 3-digit exponent, so the product keeps Calc's form.

Status: accepted · depends on `wi-a-v1-number-text-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-nt-suite` | b1 | `tests/values/checks/a_v1_nt_suite.sh` | red | — |
| `ac-nt-judge` | b1 | `judge:Usefulness only (not Calc fidelity): through ./engine as shipped, when an ordinary user builds labels and messages from numbers (="Total: "&A1 for amounts, tiny rates and big counts, CONCATENATE, LEN of a number), do they get readable text (0.0000001, not 1E-07; 1000000000000000, not 1E+15) as they would in a spreadsheet? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | number-to-text conversion in &, CONCATENATE, LEN and the text functions matches LibreOffice over a set of small, large and fractional numbers, with expected values from running LibreOffice | `tests/values/checks/a_v1_nt_b1_text.sh` — |

## 5. Out of scope and risks

- **Out of scope:** the grid's display (a-v1-entry-display)
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/values/**`, `exp-a:tests/values/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-number-text-1` | `impl-a1@alebairos` |
| Reviewed `wi-a-v1-number-text-1` | `rev-a@alebairos` (passed attempt 2) |
| Implemented `wi-a-v1-number-text-2` | — |
| Reviewed `wi-a-v1-number-text-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-a-v1-number-text-1`:

- `tests/values/checks/a_v1_nt_probe.py` +47 −0 (plan check)
- `tests/values/checks/a_v1_nt_b1_text.sh` +29 −0 (plan check)
- `src/values/__init__.py` +16 −12
- `tests/values/checks/a_v1_nt_suite.sh` +27 −0 (plan check)
- `tests/values/test_values.py` +12 −1 (test)
- `tests/values/checks/a_v1_nt_calc.json` +1 −0 (plan check)

Landing pull request: [exp-a #25](https://github.com/alebairos/sheet-exp-a/pull/25)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 2 h 18 min so far
- Loops: 1 (D5 review 1)
- Waste: 6 min
- Size: 28 lines (+16 −12, 2 files, ≤400; tests 13 lines); plan check files laid over by land, not in the size: +104 −0, 4 files
