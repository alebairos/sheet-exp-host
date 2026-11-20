# Intent `a-r1-engine`

## 1. Outcome

> The engine computes whole workbooks end to end through the CLI: formulas, functions and recalculation together

Kind: Feature · State: awaiting the verdict · 1 work item · 2 bullets

## 2. What you will see

Whole workbooks computed end to end through the engine CLI, as the hidden suite will: a three-sheet workbook (Data, Summary, Calc) that uses all 40 functions together, references across sheets in both directions, numeric text, a boolean, a failed lookup caught by IFERROR and a division by zero; and a workbook with 100-formula chains where a #DIV/0! at A40 flows to A100 and through SUM, a #N/A from VLOOKUP flows through 100 text formulas on another sheet, and a chain written bottom-up still computes in dependency order. Every cell equals what LibreOffice Calc gave for the same workbook. The media is Calc's answer sheet for every formula.

- [a-r1-engine/README.md](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/README.md)
- [a-r1-engine/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/calc-answers.md)
- [a-r1-engine/books.json](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/books.json)
- [a-r1-engine/calc.json](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/calc.json)
- [a-r1-engine/books.py](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/books.py)
- [a-r1-engine/bookprobe.py](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/bookprobe.py)
- [a-r1-engine/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/dfc9676dcbc1e329eba6382b5dd8cc239fb13049/a-r1-engine/gencheck.py)

## 3. Approach

The engine on main already computes both workbooks exactly as Calc (0 mismatches, measured over every cell), so no engine code changes (out of scope, and forbidden in the WI). One WI adds the product's own e2e suite: tests/e2e/__init__.py and tests/e2e/engine/__init__.py so ./test.sh discovers it, workbooks in tests/e2e/engine/books/<name>.json with Calc's answers in <name>.calc.json (the evidence's books.json/calc.json can be copied as is), and a unittest that runs ./engine on each workbook and compares every cell (numbers within 1e-9). The checks hold their own copy of the two workbooks and Calc's answers, in files next to the scripts (tests/e2e/engine/checks: a_r1_b*_book.json and _calc.json, compact, one line per sheet; the shared helpers in a_r1_common.py and a_r1_chain.py, so every check file stays under 80 lines) and also require the product suite to have them: workbooks covering all 40 functions with a cross-sheet formula (b1), and one with a 100-long chain whose Calc answers carry an error (b2), all computing as their .calc.json says and the e2e tests passing.

- **Reuses:** The engine CLI (./engine, src.cli) as it is; the Calc probe over UNO from a-i5/a-i7's evidence, extended to load a whole workbook and read every cell.
- **Removes:** tests/e2e/README.md's placeholder may be replaced by a note on the suite; nothing else.
- **Rejected:** Fixing behaviour here: none is wrong, and changing the parts' code is out of scope. Checks that only run the embedded workbooks: they pass on base, so they cannot prove this intent's work; requiring the product's own e2e suite is what this intent adds. Comparing against Excel or hand-computed values: the suite is LibreOffice's. A per-formula probe (append formulas to a fixture): it misses dependency order and propagation across a whole workbook, which is the point of b2.

## 4. Work items

### `wi-a-r1-engine-1`: End-to-end workbook tests

Adds the product's end-to-end suite under tests/e2e/engine: whole multi-sheet workbooks (every function group, cross-sheet formulas, and a 100-formula chain carrying an error) run through ./engine and compared cell by cell with LibreOffice Calc's answers, so ./test.sh guards the engine as a whole.

Status: landed (`19f721db9d31`)

**The passing review noted:** > PASS (attempt 2), wi-a-r1-engine-1 @ cdadae2. This is the same commit I passed on attempt 1, and that review's evidence stands: base red on both checks, both checks green, 7 files all in scope, and the .calc.json answers match a LibreOffice recompute cell for cell (534 cells, 0 mismatches).
> - Why it came back: the code is not at fault. Land run 44665161642 staged it with "tests green", then the push to the product failed on GitHub's side ("remote: error: unable to write file .../objects/.../pack-847394aa...pack: No such file or directory"). CompleteLanding then reported LandAborted because the head of cooknship/a-r1-engine was not b4f0ced. That is an infrastructure failure, so resubmitting the same code for this reason is legitimate.
> - Re-verified against current exp-a main (c6b525f, after i5-math and i6-logic-text landed): cdadae2 already contains it (the merge fast-forwards). On it, tests/e2e/engine/checks/a_r1_b1_workbooks.sh (ac-r1-b1, b1) prints "ok", tests/e2e/engine/checks/a_r1_b2_chain.sh (ac-r1-b2, b2) prints "ok", and ./test.sh runs 66 tests, all OK.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r1-b1` | b1 | `tests/e2e/engine/checks/a_r1_b1_workbooks.sh` | red | pass |
| `ac-r1-b2` | b2 | `tests/e2e/engine/checks/a_r1_b2_chain.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | multi-sheet workbooks mixing every function group compute as Calc does | `tests/e2e/engine/checks/a_r1_b1_workbooks.sh` pass |
| PASS | b2 | a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc | `tests/e2e/engine/checks/a_r1_b2_chain.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** the UI; changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:tests/e2e/engine/**`, `exp-a:tests/e2e/__init__.py`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-r1-engine-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-r1-engine-1` | `rev-a@alebairos` (passed attempt 2) |

Product checks:

- `tests/e2e/engine/checks/a_r1_b1_workbooks.sh`: pass
- `tests/e2e/engine/checks/a_r1_b2_chain.sh`: pass

Outcome report: none yet.

Files landed by `wi-a-r1-engine-1`:

- `tests/e2e/engine/test_workbooks.py` +81 −0 (test)
- `tests/e2e/engine/checks/a_r1_common.py` +77 −0 (plan check)
- `tests/e2e/engine/checks/a_r1_b1_workbooks.sh` +44 −0 (plan check)
- `tests/e2e/engine/checks/a_r1_chain.py` +41 −0 (plan check)
- `tests/e2e/engine/checks/a_r1_b2_chain.sh` +39 −0 (plan check)
- `tests/e2e/engine/books/mixed.calc.json` +5 −0 (test)
- `tests/e2e/engine/books/mixed.json` +5 −0 (test)
- `tests/e2e/engine/checks/a_r1_b1_book.json` +5 −0 (plan check)
- `tests/e2e/engine/checks/a_r1_b1_calc.json` +5 −0 (plan check)
- `tests/e2e/engine/books/chain.calc.json` +4 −0 (test)
- `tests/e2e/engine/books/chain.json` +4 −0 (test)
- `tests/e2e/engine/checks/a_r1_b2_book.json` +4 −0 (plan check)
- `tests/e2e/engine/checks/a_r1_b2_calc.json` +4 −0 (plan check)
- `tests/e2e/__init__.py` +0 −0 (test)
- `tests/e2e/engine/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #18](https://github.com/alebairos/sheet-exp-a/pull/18)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 25 h 04 min so far
- Loops: 5 (D1 spec 1, D2 plan 3, D6 landing 1)
- Waste: 34 min
- Size: 0 lines (+0 −0, 7 files, ≤400; tests 99 lines); plan check files laid over by land, not in the size: +219 −0, 8 files
