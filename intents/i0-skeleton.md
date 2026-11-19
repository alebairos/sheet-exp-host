# Intent `i0-skeleton`

## 1. Outcome

> The engine CLI exists and builds and tests from a clean clone with ./test.sh: it reads a workbook JSON (SPEC.md) and prints it back with constants unchanged, and the repo has one directory per part (src/parser, src/values, src/eval, src/recalc, src/functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e) with a way to register functions that needs no shared file edits

Kind: Feature · State: in work · 1 work item · 3 bullets

## 2. What you will see

A runnable ./engine that reads SPEC.md workbook JSON from stdin (-) and prints the same constants workbook back, or one cell with --cell. The repo has the part directories listed in the outcome, a function-registration hook that discovers packages under src/functions without editing a shared registry file, and ./test.sh runs a real suite via scripts/test from a clean clone.

- No media: CLI and directory skeleton only; no UI surface in this intent.

## 3. Approach

Python 3 so a clean clone needs no compiler. One work item: add the directory tree and empty packages, a discovery-based function registry (importlib scans src/functions/*), a small CLI that parses workbook JSON and echoes constants (formulas out of scope), wire ./engine and scripts/test so ./test.sh exercises the constants roundtrip and --cell cases.

- **Reuses:** SPEC.md workbook JSON shape; existing ./test.sh that delegates to scripts/test when present.
- **Removes:** The seed ./test.sh path that only prints "no tests yet".
- **Rejected:** A single-file engine with a hand-maintained function table — later intents need separate packages and registration without shared-file edits. Also rejected shipping formula evaluation here — out of scope.

## 4. Work items

### `wi-i0-skeleton-1`: Skeleton and constants CLI

Add the part directories, discovery-based function registry, ./engine that echoes constants from workbook JSON (and --cell), and wire ./test.sh to a real suite.

Status: queued to land

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
| `ac-b1` | b1 | `scripts/checks/b1_constants_roundtrip.sh` | red | — |
| `ac-b2` | b2 | `scripts/checks/b2_cell_flag.sh` | red | — |
| `ac-b3` | b3 | `scripts/checks/b3_test_sh.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | `engine -` prints a workbook of constants unchanged, in SPEC.md's output shape | no landed check |
| not yet | b2 | `engine - --cell Sheet1!A1` prints one value | no landed check |
| not yet | b3 | ./test.sh builds and runs every test from a clean clone | no landed check |

## 5. Out of scope and risks

- **Out of scope:** formulas; functions; the UI
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i0-skeleton-1` | `impl-1@alebairos` |
| Reviewed `wi-i0-skeleton-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

- Held: `wi-i0-skeleton-1`: wi-i0-skeleton-1 at 06cd09fb76b1: intent i0-skeleton was certified without its plan commit (no plan_oid), so land cannot lay the certified checks over and an edited check would decide; certify the new plan with its plan_oid. Held for the HITL, no attempt counted. The way out: Replan i0-skeleton, so the plan is cut again on the current product; or, once a WI of it has landed, shelve it with a replacement

## 7. The decision

**Held landing `wi-i0-skeleton-1`**: wi-i0-skeleton-1 at 06cd09fb76b1: intent i0-skeleton was certified without its plan commit (no plan_oid), so land cannot lay the certified checks over and an edited check would decide; certify the new plan with its plan_oid. Held for the HITL, no attempt counted. The way out: Replan i0-skeleton, so the plan is cut again on the current product; or, once a WI of it has landed, shelve it with a replacement

## 8. Metrics

- Lead time: 1 h 48 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
