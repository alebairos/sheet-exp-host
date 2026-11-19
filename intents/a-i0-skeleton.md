# Intent `a-i0-skeleton`

## 1. Outcome

> The engine CLI exists and builds and tests from a clean clone with ./test.sh: it reads a workbook JSON (SPEC.md) and prints it back with constants unchanged, and the repo has one directory per part (src/parser, src/values, src/eval, src/recalc, src/functions/{math,logic_text,lookup}, web/{grid,formula_bar,io}, tests/e2e) with a way to register functions that needs no shared file edits

Kind: Feature · State: in work · 1 work item · 3 bullets

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

Status: landing (`c772837d2a38`)

**The passing review noted:** > PASS. Verify rerun on e5888e5 (clean worktree): all three checks green, and all three red on base 4a38d02. ./test.sh: 10 tests OK.
> - ac-a0-b1 (b1) scripts/checks/a0_b1_constants.sh: ok. src/cli.py:14-17 compute() copies every sheet's cells unchanged (stdin via load() src/cli.py:7-9, or a file path src/cli.py:10-11) and json.dump writes the {"sheets":...} shape (src/cli.py:51). Types are preserved, which tests/test_cli.py:34-38 also covers.
> - ac-a0-b2 (b2) scripts/checks/a0_b2_cell.sh: ok. src/cli.py:20-29 cell_value prints one JSON value; it strips $ (tested in tests/test_cli.py:48-49); a blank cell gives null and an unknown sheet gives {"error":"#REF!"}.
> - ac-a0-b3 (b3) scripts/checks/a0_b3_test_sh.sh: ok. ./test.sh delegates to scripts/test:6 (unittest discover, PYTHONDONTWRITEBYTECODE=1 set at scripts/test:5 for land's read-only tree). All 11 part directories exist. src/functions/__init__.py:21-45 register()/registry() discover a module dropped into src/functions/<group>/ with no edit to a shared file.
> Scope: every path is inside exp-a/** (the intent's scope is the whole repo). README.md documents the one command, as SPEC asks.
> Notes, not blocking: (1) formula strings pass through unchanged, which fits this intent since formulas are out of scope; i3/i4 replace compute(). (2) --cell normalises the ref to upper case but not the input's keys, so a lower-case key like "a1" is missed; SPEC's input uses upper case. (3) --cell without a sheet uses the first sheet (src/cli.py:22-23); SPEC always qualifies the ref.
> -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a0-b1` | b1 | `scripts/checks/a0_b1_constants.sh` | red | — |
| `ac-a0-b2` | b2 | `scripts/checks/a0_b2_cell.sh` | red | — |
| `ac-a0-b3` | b3 | `scripts/checks/a0_b3_test_sh.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | `engine -` prints a workbook of constants unchanged, in SPEC.md's output shape | no landed check |
| not yet | b2 | `engine - --cell Sheet1!A1` prints one value | no landed check |
| not yet | b3 | ./test.sh builds and runs every test from a clean clone | no landed check |

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

Product checks: not recorded yet.

Outcome report: none yet.

- Held: `wi-a-i0-skeleton-1`: wi-a-i0-skeleton-1: turn on auto-merge (merge commit) on https://github.com/alebairos/sheet-exp-a/pull/2, or merge it yourself; GitHub refused it: GraphQL: Pull request Pull request is in clean status (enablePullRequestAutoMerge) (auto-merge needs a public repo or a paid plan; a merge queue or a linear-history rule is not supported: land this product in direct mode)

Landing pull request: [exp-a #2](https://github.com/alebairos/sheet-exp-a/pull/2)

## 7. The decision

**Held landing `wi-a-i0-skeleton-1`**: wi-a-i0-skeleton-1: turn on auto-merge (merge commit) on https://github.com/alebairos/sheet-exp-a/pull/2, or merge it yourself; GitHub refused it: GraphQL: Pull request Pull request is in clean status (enablePullRequestAutoMerge) (auto-merge needs a public repo or a paid plan; a merge queue or a linear-history rule is not supported: land this product in direct mode)

## 8. Metrics

- Lead time: 32 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
