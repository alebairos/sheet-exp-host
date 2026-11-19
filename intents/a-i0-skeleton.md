# Intent `a-i0-skeleton`

## 1. Outcome

> The engine CLI exists and builds and tests from a clean clone with ./test.sh: it reads a workbook JSON (SPEC.md) and prints it back with constants unchanged, and the repo has one directory per part (src/parser, src/values, src/eval, src/recalc, src/functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e) with a way to register functions that needs no shared file edits

Kind: Feature · State: Met · 1 work item · 3 bullets

## 2. What you will see

An executable ./engine at the repo root: `./engine - < book.json` (or `./engine book.json`) prints the workbook back in SPEC.md's shape with every constant unchanged; `./engine - --cell Sheet1!A1` prints just that cell's JSON value. The repo has one directory per part: src/parser, src/values, src/eval, src/recalc, src/functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e. ./test.sh runs the whole suite from a fresh copy and fails if any test fails.

- No media: a command-line skeleton with no screen; the sample input and output are in the plan's checks (scripts/checks/a0_*.sh)

## 3. Approach

Python 3 standard library only, so a clean clone (and the land runner's ubuntu image) needs nothing installed. The CLI first (the hidden suite's contract): ./engine is a small python3 launcher that puts the repo root on sys.path and calls src/cli.py, which reads JSON from a file or stdin, keeps every non-formula value as is, and writes JSON (or one cell for --cell). Every directory under src/ is a package (src/__init__.py included). src/functions/__init__.py exposes register(name) (a decorator) and registry() (a name -> callable dict); registry() imports every module found in src/functions/<group>/ with pkgutil, so a function lands by adding its own file, never by editing a shared list. web/* and tests/e2e hold a README placeholder until their intents. scripts/test runs `python3 -m unittest discover -s tests -t .` (tests/__init__.py present) and ./test.sh already delegates to it; unit tests cover the CLI round trip, --cell and the registry. Set PYTHONDONTWRITEBYTECODE in scripts/test: land runs tests on a read-only tree.

- **Reuses:** SPEC.md's workbook JSON shape; the seed ./test.sh, which already runs scripts/test when it exists.
- **Removes:** none (the seed test.sh's "no tests yet" branch stops being reached once scripts/test exists)
- **Rejected:** A compiled stack (Rust/Go/Java): needs a toolchain in the land workflow and in every clean clone. Node for the engine: possible, but Python's float formatting and Decimal suit Calc's number rules for later intents. A hand-maintained function table: every function intent would edit the same file and collide.

## 4. Work items

### `wi-a-i0-skeleton-1`: Engine CLI skeleton and test suite

Add the part directories, a function registry that discovers files under src/functions, an ./engine CLI that echoes a constants workbook (or one cell with --cell), and a real unittest suite behind ./test.sh, so every later intent has a place to land and a suite to grow.

Status: landed (`c772837d2a38`)

**The passing review noted:** > PASS. Verify rerun on e5888e5 (clean worktree): all three checks green, and all three red on base 4a38d02. ./test.sh: 10 tests OK.
> - ac-a0-b1 (b1) scripts/checks/a0_b1_constants.sh: ok. src/cli.py:14-17 compute() copies every sheet's cells unchanged (stdin via load() src/cli.py:7-9, or a file path src/cli.py:10-11) and json.dump writes the {"sheets":...} shape (src/cli.py:51). Types are preserved, which tests/test_cli.py:34-38 also covers.
> - ac-a0-b2 (b2) scripts/checks/a0_b2_cell.sh: ok. src/cli.py:20-29 cell_value prints one JSON value; it strips $ (tested in tests/test_cli.py:48-49); a blank cell gives null and an unknown sheet gives {"error":"#REF!"}.
> - ac-a0-b3 (b3) scripts/checks/a0_b3_test_sh.sh: ok. ./test.sh delegates to scripts/test:6 (unittest discover, PYTHONDONTWRITEBYTECODE=1 set at scripts/test:5 for land's read-only tree). All 11 part directories exist. src/functions/__init__.py:21-45 register()/registry() discover a module dropped into src/functions/<group>/ with no edit to a shared file.
> Scope: every path is inside exp-a/** (the intent's scope is the whole repo). README.md documents the one command, as SPEC asks.
> Notes, not blocking: (1) formula strings pass through unchanged, which fits this intent since formulas are out of scope; i3/i4 replace compute(). (2) --cell normalises the ref to upper case but not the input's keys, so a lower-case key like "a1" is missed; SPEC's input uses upper case. (3) --cell without a sheet uses the first sheet (src/cli.py:22-23); SPEC always qualifies the ref.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a0-b1` | b1 | `scripts/checks/a0_b1_constants.sh` | red | pass |
| `ac-a0-b2` | b2 | `scripts/checks/a0_b2_cell.sh` | red | pass |
| `ac-a0-b3` | b3 | `scripts/checks/a0_b3_test_sh.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | `engine -` prints a workbook of constants unchanged, in SPEC.md's output shape | `scripts/checks/a0_b1_constants.sh` pass |
| PASS | b2 | `engine - --cell Sheet1!A1` prints one value | `scripts/checks/a0_b2_cell.sh` pass |
| PASS | b3 | ./test.sh builds and runs every test from a clean clone | `scripts/checks/a0_b3_test_sh.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** formulas; functions; the UI
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i0-skeleton-1` | `impl-a2@alebairos` |
| Reviewed `wi-a-i0-skeleton-1` | `rev-a@alebairos` (passed attempt 1) |
| Verdict (Met) | `alebairos` |

Product checks:

- `scripts/checks/a0_b1_constants.sh`: pass
- `scripts/checks/a0_b2_cell.sh`: pass
- `scripts/checks/a0_b3_test_sh.sh`: pass

Outcome report:

- **Built:** The skeleton of the spreadsheet engine is on exp-a main (PR #2, merged as 872d19d). ./engine reads a workbook JSON from stdin or a file and prints it back in SPEC.md's shape with every value unchanged; `./engine - --cell Sheet1!A1` prints that one cell. Formulas are not computed yet: a formula string is echoed as text, which is what this intent's scope allowed. The repo now has one folder per part (parser, values, eval, recalc, functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e), and new functions are picked up just by adding a file under src/functions/<group>/, so the function intents will not collide on a shared list. ./test.sh runs a 10-test Python suite from a clean clone (Python 3 standard library only, nothing to install). It followed the plan with no departures: one work item, landed on the first attempt, 155 changed lines. I re-ran ./test.sh and the CLI on main myself: 10 tests OK, constants echoed, --cell prints 5.
- **Advice:** Adopt: it is the base every other exp-a intent builds on, and all three bullets pass on landed work. Follow up (from the reviewer's notes, none blocking): --cell matches cell keys only in upper case, and with no sheet it uses the first one; the evaluator/recalc intents (a-i3, a-i4) replace the echo with real computation. Watch: the hidden suite calls ./engine, so its input and output shape here is the contract later intents must keep.
- No media: a command-line skeleton with no screen; the plan showed no files, and its sample input and output are the checks in scripts/checks/a0_*.sh

Files landed by `wi-a-i0-skeleton-1`:

- `tests/test_cli.py` +62 −0 (test)
- `src/cli.py` +57 −0
- `scripts/checks/a0_b1_constants.sh` +45 −0 (plan check)
- `src/functions/__init__.py` +45 −0
- `scripts/checks/a0_b3_test_sh.sh` +38 −0 (plan check)
- `tests/test_registry.py` +31 −0 (test)
- `scripts/checks/a0_b2_cell.sh` +22 −0 (plan check)
- `README.md` +17 −1
- `engine` +11 −0
- `scripts/test` +6 −0
- `tests/e2e/README.md` +3 −0 (test)
- `web/formula_bar/README.md` +3 −0
- `web/grid/README.md` +3 −0
- `web/io/README.md` +3 −0
- `.gitignore` +2 −0
- `src/eval/__init__.py` +1 −0
- `src/functions/logic_text/__init__.py` +1 −0
- `src/functions/lookup/__init__.py` +1 −0
- `src/functions/math/__init__.py` +1 −0
- `src/parser/__init__.py` +1 −0
- `src/recalc/__init__.py` +1 −0
- `src/values/__init__.py` +1 −0
- `src/__init__.py` +0 −0
- `tests/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #2](https://github.com/alebairos/sheet-exp-a/pull/2)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 7 h 41 min
- Loops: 0
- Waste: 0 min
- Size: 155 lines (+154 −1, 21 files, ≤400; tests 96 lines); plan check files laid over by land, not in the size: +105 −0, 3 files
