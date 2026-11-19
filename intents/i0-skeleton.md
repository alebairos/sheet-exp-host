# Intent `i0-skeleton`

## 1. Outcome

> The engine CLI exists and builds and tests from a clean clone with ./test.sh: it reads a workbook JSON (SPEC.md) and prints it back with constants unchanged, and the repo has one directory per part (src/parser, src/values, src/eval, src/recalc, src/functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e) with a way to register functions that needs no shared file edits

Kind: Feature · State: Met · 1 work item · 3 bullets

## 2. What you will see

A runnable ./engine that reads SPEC.md workbook JSON from stdin (-) and prints the same constants workbook back, or one cell with --cell. The repo has the part directories listed in the outcome, a function-registration hook that discovers packages under src/functions without editing a shared registry file, and ./test.sh runs a real suite via scripts/test from a clean clone.

- No media: CLI and directory skeleton only; no UI surface in this intent.

## 3. Approach

Python 3 so a clean clone needs no compiler. One work item: add the directory tree and empty packages, a discovery-based function registry (importlib scans src/functions/*), a small CLI that parses workbook JSON and echoes constants (formulas out of scope), wire ./engine and scripts/test so ./test.sh exercises the constants roundtrip and --cell cases.

- **Reuses:** SPEC.md workbook JSON shape; existing ./test.sh that delegates to scripts/test when present.
- **Removes:** The seed ./test.sh path that only prints "no tests yet".
- **Rejected:** A single-file engine with a hand-maintained function table — later intents need separate packages and registration without shared-file edits. Also rejected shipping formula evaluation here — out of scope.

## 4. Work items

### `wi-i0-skeleton-1`: Constants CLI skeleton

Add the part directories, discovery-based function registry, and a Python ./engine that echoes constants so ./test.sh runs a real suite from a clean clone.

Status: landed (`fa58829a5cba`)

**The passing review noted:** > pass wi-i0-skeleton-1 against ACs b1-b3 at commit 06cd09f (diff origin/main...06cd09f).
> 
> ac-b1 / scripts/checks/b1_constants_roundtrip.sh: PASS (exit 0). ./engine - echoes constants workbook unchanged in SPEC.md shape. Evidence: src/cli.py:17-29 compute_constants; src/cli.py:60-65 dump; engine:1-6 launches python3 -m src.cli. Manual and check agree.
> 
> ac-b2 / scripts/checks/b2_cell_flag.sh: PASS (exit 0). ./engine - --cell Sheet1!A1 prints one JSON value. Evidence: src/cli.py:32-42 cell_value; src/cli.py:60-62 --cell branch.
> 
> ac-b3 / scripts/checks/b3_test_sh.sh: PASS (exit 0). ./test.sh runs real suite via scripts/test (not seed stub). Evidence: test.sh:4 delegates; scripts/test:19-60 covers roundtrip, --cell, discover_functions, part_dirs; ./test.sh exit 0 "all tests passed".
> 
> Outcome extras: part dirs present (src/parser,values,eval,recalc; functions/{math,logic_text,lookup}; web/{grid,formula_bar,io}; tests/e2e). Registry discovers packages via pkgutil without a hand-edited table: src/functions/registry.py:9-20.
> 
> Scope: path_scope exp-b:/**; all 18 changed paths in scope (.gitignore belongs, drops __pycache__). Out of scope formulas/functions/UI not implemented. Formulas left as literal strings in constants pass (src/cli.py:26-27), matching this intent.
> 
> No fail findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `scripts/checks/b1_constants_roundtrip.sh` | red | pass |
| `ac-b2` | b2 | `scripts/checks/b2_cell_flag.sh` | red | pass |
| `ac-b3` | b3 | `scripts/checks/b3_test_sh.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | `engine -` prints a workbook of constants unchanged, in SPEC.md's output shape | `scripts/checks/b1_constants_roundtrip.sh` pass |
| PASS | b2 | `engine - --cell Sheet1!A1` prints one value | `scripts/checks/b2_cell_flag.sh` pass |
| PASS | b3 | ./test.sh builds and runs every test from a clean clone | `scripts/checks/b3_test_sh.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** formulas; functions; the UI
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i0-skeleton-1` | `impl-2@alebairos` |
| Reviewed `wi-i0-skeleton-1` | `rev-1@alebairos` (passed attempt 2) |
| Verdict (Met) | `alebairos` |

Product checks:

- `scripts/checks/b1_constants_roundtrip.sh`: pass
- `scripts/checks/b2_cell_flag.sh`: pass
- `scripts/checks/b3_test_sh.sh`: pass

Outcome report:

- **Built:** exp-b now has a Python ./engine that reads SPEC.md workbook JSON from stdin and prints constants unchanged, or one value with --cell Sheet1!A1. Landed commit fa58829 adds the planned part directories (src/parser, values, eval, recalc, functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e), a discovery registry under src/functions/registry.py that finds packages without a hand-edited table, and scripts/test so ./test.sh runs a real suite. Stayed on plan: no formula evaluation, no UI. One small follow-up already in the land: __pycache__ ignored and dropped from the tree.
- **Advice:** Adopt. The skeleton is the base for later formula and function intents. Watch that new function packages keep landing as subpackages under src/functions so discovery stays zero-touch. Follow up only if a later intent needs shared helpers outside those packages.
- No media: CLI and directory skeleton only; no UI surface in this intent.

Files landed by `wi-i0-skeleton-1`:

- `src/cli.py` +70 −0
- `scripts/test` +66 −0
- `src/functions/registry.py` +20 −0
- `scripts/checks/b1_constants_roundtrip.sh` +16 −0 (plan check)
- `scripts/checks/b2_cell_flag.sh` +14 −0 (plan check)
- `scripts/checks/b3_test_sh.sh` +7 −0 (plan check)
- `engine` +6 −0
- `.gitignore` +3 −0
- `tests/e2e/.gitkeep` +1 −0 (test)
- `web/formula_bar/.gitkeep` +1 −0
- `web/grid/.gitkeep` +1 −0
- `web/io/.gitkeep` +1 −0
- `src/__init__.py` +0 −0
- `src/eval/__init__.py` +0 −0
- `src/functions/__init__.py` +0 −0
- `src/functions/logic_text/__init__.py` +0 −0
- `src/functions/lookup/__init__.py` +0 −0
- `src/functions/math/__init__.py` +0 −0
- `src/parser/__init__.py` +0 −0
- `src/recalc/__init__.py` +0 −0
- `src/values/__init__.py` +0 −0

Landing pull request: [exp-b #2](https://github.com/alebairos/sheet-exp-b/pull/2)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 9 h 19 min
- Loops: 0
- Waste: 0 min
- Size: 168 lines (+168 −0, 18 files, ≤400; tests 1 lines); plan check files laid over by land, not in the size: +37 −0, 3 files
