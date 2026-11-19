# Intent `a-i4-recalc`

## 1. Outcome

> A workbook recalculates in dependency order, recomputes only what an edit affects, and reports a circular reference as an error instead of hanging

Kind: Feature · State: awaiting the verdict · 1 work item · 4 bullets

## 2. What you will see

./engine finally computes formulas: today it echoes them back as text. Give it a workbook whose cells are in any order, across sheets, and every formula is computed after the cells it reads (A3 =A2+A1 written before A1 still gives the right number; Sheet1!B1 =Sheet2!A1*10 works when Sheet2!A1 is itself a formula). A circular reference (A1 =B1+1, B1 =A1+1, or a cell reading itself) does not hang: every cell on the cycle, and every formula reading one, shows {"error": "Err:522"}, as LibreOffice shows it; the rest of the sheet computes normally. For the browser and later work, src/recalc also keeps a workbook live: change one cell and only the formulas that depend on it are recomputed, so a 10,000-cell chain recomputes in well under a second. The media holds LibreOffice's own answer for a circular sheet and a sample input with the engine's output.

- [a-i4-recalc/README.md](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/README.md)
- [a-i4-recalc/circular-libreoffice.csv](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/circular-libreoffice.csv)
- [a-i4-recalc/circular.fods](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/circular.fods)
- [a-i4-recalc/sample-in.json](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/sample-in.json)
- [a-i4-recalc/sample-out.json](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/sample-out.json)

## 3. Approach

One module, src/recalc, on top of the evaluator (a-i3), most-value part first: dependency-ordered compute through the CLI. Workbook(book) parses each formula once and collects its references (walking the parser's tree for Ref and Range nodes; sheet names matched case-insensitively as the evaluator does; a missing sheet gives no edge, the evaluator returns #REF!). It keeps a values book where each constant is its src.values Value and each formula cell holds its computed Value; the evaluator's Range reads that book (from_json passes Values through), so a formula always sees its precedents already computed. Order is an iterative depth-first topological sort (no Python recursion, so a 10,000-cell chain or a 5,000-cell cycle is safe); cells found on a cycle get Error('Err:522'), and so does any formula that reads one, before it would be evaluated. Dependents: a map from a cell to the formulas naming it, plus a list of range references checked by rectangle, so an edit inside a range (even a blank cell) finds its readers. set(sheet, addr, raw) re-parses that one cell, updates its edges, collects the transitive dependents and recomputes just those in order, returning the set it recomputed; computed() writes formulas back through to_json, constants exactly as given, cells in input order. compute(book) = Workbook(book).computed(). src/cli.py's compute() calls src.recalc.compute (two lines; still never aliases the input). Unit tests in tests/recalc. Measured by the planner's throwaway prototype: 10,000-cell chain computes in 0.17 s, edits in 0.06 s.

- **Reuses:** src.parser.parse and its Ref/Range nodes (a-i1); src.values Values, from_json/to_json (a-i2); src.eval.evaluate_node and its Range reader (a-i3), unchanged; the engine launcher and src/cli.py's argument handling and --cell (a-i0).
- **Removes:** src/cli.py's pass-through compute() body (formulas are no longer echoed as text).
- **Rejected:** Recursive evaluation on demand (the evaluator calling back into recalc for each referenced cell): simpler, but a 10,000-cell chain overflows Python's recursion limit and the evaluator would need changing outside this scope. Recomputing the whole workbook on every edit: meets b1 and b3 but not b2, and costs the browser a full pass per keystroke. Calc's iterative calculation setting (converging cycles): off by default in Calc, so the hidden suite sees Err:522. Pinning #VALUE! or another SPEC code for cycles: LibreOffice headless gives Err:522 (see the media). Wiring the CLI in a later intent: a-r1-engine's scope is only tests/e2e/engine and excludes changing the parts, so nothing else would connect the CLI to the engine; src/cli.py joins this scope for that.

## 4. Work items

### `wi-a-i4-recalc-1`: Recalculation: order, edits, cycles

Add src/recalc (a workbook that computes formulas in dependency order, recomputes only an edit's dependents, and gives Err:522 on circular references) and point the CLI's compute at it, so ./engine computes formulas instead of echoing them.

Status: landed (`f91e897d51b2`)

**The passing review noted:** > PASS. Reran verify on the WI commit 2e3abb2 (worktree): all four checks green, all four red on the plan commit 1040c0a (base); ./test.sh 64 tests OK.
> - ac-a4-b1 (b1, tests/recalc/checks/a4_b1_order.sh: ok b1): src/recalc/__init__.py:188 _recompute orders formulas with an iterative Tarjan pass over _precedents (points plus formula cells inside ranges), so precedents are evaluated first; src/cli.py:18 now routes ./engine through src.recalc.compute. Probed: cross-sheet with a lower-case sheet name (=sheet2!A1*2 where Sheet2!A1 is a formula) gives 8.
> - ac-a4-b2 (b2, a4_b2_incremental.sh: ok b2): src/recalc/__init__.py:244 set() re-parses one cell, then walks _dependents (src/recalc/__init__.py:175, point readers plus range readers by rectangle) to the transitive closure and recomputes only that set. Probed: editing a blank B3 inside SUM(B1:B5) returns {A1}; breaking a cycle (B1 :=5) recomputes only {A1,C1}; creating one by edit marks all three Err:522.
> - ac-a4-b3 (b3, a4_b3_cycles.sh: ok b3): src/recalc/__init__.py:233 a strongly connected component of >1 cell, or a self-read (also through a range, =SUM(A1:A3) in A1), becomes Err:522 without evaluation; readers get the error by ordinary propagation. A 5,000-cell cycle computes in 0.05 s with no recursion.
> - ac-a4-b4 (b4, a4_b4_speed.sh: ok b4): chain-head edit 9,999 recomputed in 0.071 s; edit read by 10,000 cells in 0.058 s.
> Scope: the diff touches src/cli.py, src/recalc/__init__.py, tests/recalc/__init__.py, tests/recalc/test_recalc.py, all inside the intent's path scope; no check file edited.
> Notes, not blocking: (1) a formula that fails to parse yields #VALUE! (src/recalc/__init__.py:113); LibreOffice reports a syntax error code (Err:5xx) there, worth pinning when the hidden suite's parse-error cases are looked at. (2) set() on a sheet not yet in the book rebuilds the whole workbook (src/recalc/__init__.py:251), correct but not incremental; fine for now. (3) Cycle readers rely on the error propagating, so IFERROR(cycle_cell, x) will return x once functions land; the design text says readers "show Err:522", which holds only for propagating readers, matching LibreOffice per the commit message.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a4-b1` | b1 | `tests/recalc/checks/a4_b1_order.sh` | red | pass |
| `ac-a4-b2` | b2 | `tests/recalc/checks/a4_b2_incremental.sh` | red | pass |
| `ac-a4-b3` | b3 | `tests/recalc/checks/a4_b3_cycles.sh` | red | pass |
| `ac-a4-b4` | b4 | `tests/recalc/checks/a4_b4_speed.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | chains of formula cells compute in dependency order | `tests/recalc/checks/a4_b1_order.sh` pass |
| PASS | b2 | an edit recomputes only its dependents | `tests/recalc/checks/a4_b2_incremental.sh` pass |
| PASS | b3 | a cycle gives an error | `tests/recalc/checks/a4_b3_cycles.sh` pass |
| PASS | b4 | 10,000 dependent cells recompute in under one second | `tests/recalc/checks/a4_b4_speed.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Path scope:** `exp-a:src/recalc/**`, `exp-a:tests/recalc/**`, `exp-a:src/cli.py`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i4-recalc-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-i4-recalc-1` | `rev-a@alebairos` (passed attempt 1) |

Product checks:

- `tests/recalc/checks/a4_b1_order.sh`: pass
- `tests/recalc/checks/a4_b2_incremental.sh`: pass
- `tests/recalc/checks/a4_b3_cycles.sh`: pass
- `tests/recalc/checks/a4_b4_speed.sh`: pass

Outcome report:

- **Built:** Landed on exp-a main (f91e897, PR #9, first attempt): src/recalc, which computes a workbook in dependency order, keeps it live so a set() recomputes only the edited cell's dependents, and marks a cycle as Err:522. src/cli.py now calls it, so ./engine computes formulas instead of echoing them. I re-ran all four checks on landed main and they pass: a4_b1_order, a4_b2_incremental, a4_b3_cycles and a4_b4_speed (an edit read by 10,000 cells recomputed them in 0.057 s, against a limit of 1 s). The full suite passes too (64 tests). A live run of ./engine on {Sheet1: A3 =A2+A1 written before A1=2, A2 =A1*3, B1 =Sheet2!A1*10, C1 =C2+1, C2 =C1+1, C3 =C1&"x"; Sheet2: A1 =4+1} gave A3 8, A2 6, B1 50, Sheet2!A1 5, and C1, C2 and C3 all {"error": "Err:522"}. That is in order, across sheets, and the cycle plus its reader are errors while the rest computes. Because ./engine now evaluates, the open/save page from a-i11 also shows computed formulas (B1 = 14 in its example).
- **Advice:** Try it in a clone of exp-a: echo '{"sheets":{"Sheet1":{"A1":2,"B1":"=A1*3","C1":"=D1+1","D1":"=C1"}}}' | ./engine -  should give B1 6 and C1, D1 Err:522. Then compare it with the media's sample-in.json/sample-out.json and LibreOffice's own circular sheet (circular-libreoffice.csv). Functions such as SUM are still #NAME? until a-i5/a-i6/a-i7 land; that is outside this scope. Every bullet, including the 10,000-cell speed bullet, holds on landed code, so Met fits.
- [a-i4-recalc/README.md](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/README.md)
- [a-i4-recalc/circular-libreoffice.csv](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/circular-libreoffice.csv)
- [a-i4-recalc/circular.fods](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/circular.fods)
- [a-i4-recalc/sample-in.json](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/sample-in.json)
- [a-i4-recalc/sample-out.json](https://github.com/alebairos/sheet-exp-host/blob/8b6ef1e6ca4072d58f9f474a0c669723ea49547e/a-i4-recalc/sample-out.json)

Files landed by `wi-a-i4-recalc-1`:

- `src/recalc/__init__.py` +290 −1
- `tests/recalc/checks/a4_b2_incremental.sh` +101 −0 (plan check)
- `tests/recalc/test_recalc.py` +91 −0 (test)
- `tests/recalc/checks/a4_b1_order.sh` +89 −0 (plan check)
- `tests/recalc/checks/a4_b4_speed.sh` +78 −0 (plan check)
- `tests/recalc/checks/a4_b3_cycles.sh` +75 −0 (plan check)
- `src/cli.py` +4 −3
- `tests/recalc/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #9](https://github.com/alebairos/sheet-exp-a/pull/9)

## 7. The decision

**Verdict:a-i4-recalc**: A decision: show your human its options

- Met: `cooknship decide --answer Verdict:a-i4-recalc --option met`
- Partially met: unmet bullets park as follow-ups: `cooknship decide --answer Verdict:a-i4-recalc --option partially`
- Not met: every unmet bullet parks as a follow-up: `cooknship decide --answer Verdict:a-i4-recalc --option not_met`

## 8. Metrics

- Lead time: 21 h 21 min so far
- Loops: 0
- Waste: 0 min
- Size: 298 lines (+294 −4, 4 files, ≤400; tests 91 lines); plan check files laid over by land, not in the size: +343 −0, 4 files
