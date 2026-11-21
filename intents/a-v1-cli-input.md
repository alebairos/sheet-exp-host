# Intent `a-v1-cli-input`

## 1. Outcome

> The CLI fails badly on bad input. Observed: malformed or empty JSON, {"sheets":[]}, a missing file and a directory print Python tracebacks; [] and {"foo":1} silently give an empty workbook with exit 0; NaN and 1e999 print as NaN and Infinity (invalid JSON); a lowercase key "a2" is echoed but =A2 reads it blank; --cell sheet1!a1 gives #REF! and --cell Sheet1!$A$1 null; a constant 1e3 echoes as 1000.0 (G28, G29; prior S6, T7). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: in work · 2 work items · 2 bullets

## 2. What you will see

Running ./engine on a broken or wrong file prints one plain line, e.g. `engine: no such file: /x.json` or `engine: the input is not valid JSON: ... at line 1 column 13`, and exits 1: no Python traceback, and nothing half-printed on stdout. A file that is JSON but not a workbook ([], {"foo": 1}, sheets as a list, a list in a cell) is refused the same way instead of giving an empty workbook. Output is always valid JSON. Cells and sheets are read regardless of case, as in Calc: a key a2 is the cell A2 (=A2+1 gives 6), and --cell sheet1!a2, --cell '$A$3' and --cell "'my sheet'!a1" work. A constant 1e3 prints as 1000. Sample output: evidence today.txt and prototype.txt.

- [a-v1-cli-input/README.md](https://github.com/alebairos/sheet-exp-host/blob/9039910ed252993bf624523afb7741d97084868d/a-v1-cli-input/README.md)
- [a-v1-cli-input/today.txt](https://github.com/alebairos/sheet-exp-host/blob/9039910ed252993bf624523afb7741d97084868d/a-v1-cli-input/today.txt)
- [a-v1-cli-input/prototype.txt](https://github.com/alebairos/sheet-exp-host/blob/9039910ed252993bf624523afb7741d97084868d/a-v1-cli-input/prototype.txt)
- [a-v1-cli-input/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/9039910ed252993bf624523afb7741d97084868d/a-v1-cli-input/prototype.diff)

## 3. Approach

Cause, as read in src/cli.py and run on main. load() calls json.load bare, so JSONDecodeError, FileNotFoundError and IsADirectoryError surface as tracebacks. Nothing checks the shape: [] and {"foo": 1} fall through to an empty workbook, and {"sheets": []} crashes inside recalc. Python's json accepts NaN/Infinity/1e999 and writes them back, which is not JSON. Cell keys are passed through as given, while formulas read upper-case refs, so "a2" is invisible to =A2. cell_value() matches the sheet name exactly. A JSON 1e3 is a Python float and prints as 1000.0.
Fix (WI 1, src/cli.py only, about 70 lines, as in the evidence prototype). A BadInput error, caught once in main(), prints `engine: <what is wrong>` on stderr and returns 1. load() turns JSON, missing-file, directory and read errors into BadInput. JSON is read with parse_constant refusing NaN/Infinity and parse_float refusing non-finite numbers and turning integral floats into ints, so 1e3 is 1000 as a computed 1000 already prints. check(book) refuses a non-object, a missing or non-object "sheets", a sheet that is not an object, and a cell that is a list or an object other than {"error": ...}. It upper-cases cell keys ($ dropped) and refuses the same cell given twice. cell_value() matches the sheet name case-insensitively and normalises the address. json.dump(..., allow_nan=False) guards the output. Usage errors keep exit 2. WI 2 adds tests/cli/test_cli_input.py (and tests/cli/__init__.py) so ./test.sh keeps it.

Beliefs:
- ran: on main every bad input in b1 gives a 11-25 line traceback (or exit 0 with an empty workbook), and the b2 cases give A3 1, #REF! for sheet1!a2 and 1000.0. Settled by a_v1_ci_b1_bad_input.sh and a_v1_ci_b2_refs.sh, both red on main (evidence today.txt).
- ran: LibreOffice Calc 26.8.1.1 headless (a_v1_ci_probe.py, read from a_v1_ci_calc.json) reads a2 as A2 (=a2+1 gives 6), reads 'my sheet'.a1 for the sheet "My Sheet" (7), and shows 1E3 as 1000. Settled by b2.
- ran: on the prototype, b1, b2, the suite check with a stand-in test, ./test.sh (75 tests) and the engine e2e checks a_r1_b1/b2 and a_r0_b1 all pass, so turning integral floats into ints changes no stored Calc answer. Settled by the land test.
- code: src/recalc and src/values are not touched. The keys are normalised before compute, so the parser's own refs need no change. Settled by b2.
- memory: the hidden suite feeds well-formed workbooks with upper-case keys, so none of this changes its answers. Settled by the a-r0/a-r1 e2e checks staying green.
- code: the deep-formula RecursionError (G28's last case) is a-v1-engine-failure's, and it stays a traceback here. Settled by: not claimed (out of scope).

Learned from RECORD.md and the overlapping pages: S6/T7 lost a point only for tracebacks, and a-i0's follow-up already noted that --cell matched only upper case. a-i2 notes that from_json silently turns lists and other dicts into #VALUE!, which this plan refuses at the door instead. The record warns that ./engine's input and output shape is the contract (a-i0 Watch), so good input prints exactly as before except integral floats (1000.0 to 1000), and the e2e answers were re-run. Values come from running Calc, not memory. No other open intent claims src/cli.py; a-v1-engine-failure owns the deep-formula crash.

- **Reuses:** src.recalc.compute unchanged; Python's json module (parse_constant, parse_float, allow_nan); the existing usage message and exit 2 for bad arguments.
- **Removes:** The tracebacks on bad input, the silent empty workbook for non-workbook JSON, and NaN/Infinity in the output.
- **Rejected:** Catching every exception in main(): it would also hide engine bugs such as the deep-formula RecursionError, which a-v1-engine-failure fixes where it happens. Accepting NaN/1e999 and writing {"error": "#NUM!"}: they are not JSON numbers, and silently changing input is worse than saying so. Turning a list cell into #VALUE! as from_json does: the review found silent acceptance to be the problem. Keeping lower-case keys as separate cells: Calc has no such cells, and formulas could never read them. Changing src/values or src/recalc: out of this scope.

## 4. Work items

### `wi-a-v1-cli-input-1`: Plain errors and case-insensitive refs in the CLI

src/cli.py refuses bad input (malformed JSON, NaN/Infinity, wrong shape, missing file, directory) with one plain stderr line and exit 1, writes only strict JSON, and reads cell keys and --cell sheet and cell names case-insensitively with $, as Calc does.

Status: landing (`f55be7543b50`)

**The passing review noted:** > PASS. Reviewed commit db38593 (attempt 2; wi/wi-a-v1-cli-input-1) against plan 2ec3d06. Attempt 1 failed on one point: a JSON integer too large for a float gave a traceback. Attempt 2 adds _integer as parse_int (src/cli.py:37-46, wired at src/cli.py:52). It catches OverflowError, and also ValueError from Python's 4300-digit int limit.
> Verify, rerun: ac-ci-b1 a_v1_ci_b1_bad_input.sh ok (13 kinds); ac-ci-b2 a_v1_ci_b2_refs.sh ok. Both were red on base (see attempt-1 review). ./test.sh: OK (75 tests).
> Probes:
> - 1 followed by 309 zeros, and by 5000 zeros, each give the one-line "engine: the input is not valid JSON: 100000000000... (N digits) is too large for a number" with exit 1.
> - 1 followed by 308 zeros (still a finite float) is accepted. -5, 0 and 12345678901234567890 echo unchanged, and =A1*2 gives -10.
> - Every attempt-1 probe still holds (lower-case keys, #NUM! on overflow, deep nesting, BOM, --cell forms, missing file, usage exit 2).
> Per AC:
> - b1: BadInput is caught once in main() (src/cli.py, main) and load()/_parse/check() raise it for every bad-input kind.
> - b2: _number/_integer/_strict plus allow_nan=False keep the output strict JSON; CELL_KEY plus check() upper-case the keys; cell_value()/_sheet() read --cell regardless of case, quotes and $.
> Note (non-blocking): integers above 2^53 that still fit a float are echoed as typed (exact digits) while computed results print as floats. Both are valid JSON. WI 2's suite should pin the 310-digit case, since the check file is frozen.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ci-b1` | b1 | `tests/cli/checks/a_v1_ci_b1_bad_input.sh` | red | — |
| `ac-ci-b2` | b2 | `tests/cli/checks/a_v1_ci_b2_refs.sh` | red | — |

### `wi-a-v1-cli-input-2`: Product tests for CLI input

Adds tests/cli/test_cli_input.py (and tests/cli/__init__.py), run by ./test.sh, covering bad input and lower-case and $ references, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-cli-input-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ci-suite` | b1, b2 | `tests/cli/checks/a_v1_ci_suite.sh` | red | — |
| `ac-ci-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): using ./engine as shipped on their own files, mistakes included (a truncated JSON file, a wrong path, a directory, a JSON file that is not a workbook, cells or --cell typed in lower case or with $), does an ordinary user always get either the right values or one plain message saying what is wrong, never a Python traceback or invalid JSON? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | bad input (malformed JSON, wrong shape, missing file, directory) prints one plain error line on stderr and exits non-zero, with no traceback | no landed check |
| not yet | b2 | every output is valid JSON numbers; --cell accepts lower-case and $ references; lower-case cell keys are read as their cell | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the deep-formula crash (a-v1-engine-failure)
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/cli.py`, `exp-a:tests/cli/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-cli-input-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-v1-cli-input-1` | `rev-a@alebairos` (passed attempt 2) |
| Implemented `wi-a-v1-cli-input-2` | — |
| Reviewed `wi-a-v1-cli-input-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

Landing pull request: [exp-a #23](https://github.com/alebairos/sheet-exp-a/pull/23)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 1 h 37 min so far
- Loops: 1 (D5 review 1)
- Waste: 14 min
- Size: nothing landed yet
