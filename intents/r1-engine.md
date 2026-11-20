# Intent `r1-engine`

## 1. Outcome

> The engine computes whole workbooks end to end through the CLI: formulas, functions and recalculation together

Kind: Feature · State: planned · 1 work item · 2 bullets

## 2. What you will see

Whole workbooks computed end to end through the engine CLI, as the hidden suite will: a three-sheet workbook (Data, Summary, Calc) that uses all 40 functions together, references across sheets in both directions, numeric text, a boolean, a failed lookup caught by IFERROR and a division by zero; and a workbook with 100-formula chains where a #DIV/0! at A40 flows to A100 and through COUNT/SUM, a #N/A from VLOOKUP flows through 100 text formulas on another sheet, and a chain written bottom-up still computes in dependency order. Every cell equals what LibreOffice Calc gave for the same workbook. The media is Calc's answer sheet for every formula. The plan checks load those workbooks from readable JSON siblings (r1_b1_book.json / r1_b1_calc.json and r1_b2_book.json / r1_b2_calc.json) next to the shell scripts.

- [r1-engine/README.md](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/README.md)
- [r1-engine/calc-answers.md](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/calc-answers.md)
- [r1-engine/books.json](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/books.json)
- [r1-engine/calc.json](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/calc.json)
- [r1-engine/books.py](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/books.py)
- [r1-engine/bookprobe.py](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/bookprobe.py)
- [r1-engine/gencheck.py](https://github.com/alebairos/sheet-exp-host/blob/b64d33fc5ef726272f90524daebe34d1a6bbab11/r1-engine/gencheck.py)

## 3. Approach

After SpecReject: (1) out_of_scope must be: the UI; changes outside the three measured gaps (ROUND, COUNTIF "<>", COUNT over errors) and the e2e suite; no rewrites of function packages and no edits outside the path scope. The Clarified answer and SpecReject both require that wording in section 5. Park of id r1-engine is refused Duplicate and Replan is NotSigner for plan-1@alebairos, so the ledger field still shows the old OOS until a signer Shelves and Parks (or the machine grows an amend). This plan's design and the Clarified/SpecReject answers are the authority for the new OOS. (2) Check scripts no longer embed Calc pins on one line: each loads pretty-printed book+calc JSON from the same checks/ directory so the full answers and runner are readable without opening the plan commit blob. WI work unchanged: fix ROUND / COUNTIF <> / COUNT-over-error in src/functions/math and src/eval, then add tests/e2e/engine books + unittest discovery.

- **Reuses:** The engine CLI (./engine, src.cli); existing math aggregates/rounding and eval; Calc workbooks from evidence/r1-engine; the split JSON pins beside the checks.
- **Removes:** tests/e2e/.gitkeep may be replaced by the suite; nothing else.
- **Rejected:** Leaving OOS as "changing the parts' code" while scoping src: SpecReject and Gate both refuse that contradiction. Embedding Calc JSON inside the .sh on one line: SpecReject could not read the full scripts. Tests-only suite: Gate rejected earlier because main mismatches the pins. Separate Defects for the three gaps: keeps the root e2e outcome split across intents; HITL Clarify said keep this plan.

## 4. Work items

### `wi-r1-engine-1`: Calc pins then e2e suite

Fix the measured ROUND, COUNTIF <>, and COUNT-over-error gaps so the embedded Calc workbooks match, then add tests/e2e/engine so ./test.sh runs those whole-workbook checks against LibreOffice answers.

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-r1-b1` | b1 | `tests/e2e/engine/checks/r1_b1_workbooks.sh` | red | — |
| `ac-r1-b2` | b2 | `tests/e2e/engine/checks/r1_b2_chain.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | multi-sheet workbooks mixing every function group compute as Calc does | no landed check |
| not yet | b2 | a workbook with a chain of 100 formulas and an error in it computes, the error propagating as in Calc | no landed check |

## 5. Out of scope and risks

- **Out of scope:** the UI; changing the parts' code
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:tests/e2e/engine/**`, `exp-b:tests/e2e/__init__.py`, `exp-b:tests/__init__.py`, `exp-b:src/functions/math/**`, `exp-b:src/eval/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | — |
| Implemented `wi-r1-engine-1` | — |
| Reviewed `wi-r1-engine-1` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 30 h 07 min so far
- Loops: 4 (D1 spec 1, D2 plan 3)
- Waste: 2 h 43 min
- Size: nothing landed yet
