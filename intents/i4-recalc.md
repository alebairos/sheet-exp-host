# Intent `i4-recalc`

## 1. Outcome

> A workbook recalculates in dependency order, recomputes only what an edit affects, and reports a circular reference as an error instead of hanging

Kind: Feature · State: in work · 2 work items · 4 bullets

## 2. What you will see

A workbook comes back fully computed: =A1+1 after A1 is 5 becomes 6, a chain written out of order still resolves, Sheet2!A1 can depend on Sheet1!A1, and ./engine <file|-> prints those values instead of the formula text (including --cell). Change A1 and only the cells that depend on it update. Point A1 at A2 and A2 at A1 and both cells show #REF! right away instead of spinning — through recalculate and through ./engine -. A 10,000-cell chain finishes in under a second.

- No media: Library plus CLI wiring; sample workbooks and timings live in tests/recalc/checks/b*.sh

## 3. Approach

One module src/recalc on top of i3's evaluate. recalculate(book) walks every formula cell, builds a dependency graph from the parser's Ref/Range nodes, topo-sorts, and evaluates each formula against a working book where already-computed cells hold values (so evaluate keeps reading stored cells the way i3 defined). Call evaluate as src.eval.evaluate (module attribute), never a from-import binding, so the b2 spy works. A cycle yields #REF! for every cell on it and does not block the rest of the sheet. recalculate(book, changed=[(sheet, addr), ...], previous=prior_computed) recomputes only the dirty closure: formulas outside it keep previous's values and are not passed to evaluate. ./engine replaces compute_constants with recalculate so the CLI matches SPEC.md. b1 and b3 run both the library API and ./engine - (out-of-order chain, cross-sheet, --cell Sheet1!C1, and a cycle workbook with a timeout). Checks in tests/recalc/checks pin the contract.

- **Reuses:** src.eval.evaluate and its working-book convention (i3); src.parser's parse tree for collecting references; src.values to_json/from_json for the computed workbook shape.
- **Removes:** none
- **Rejected:** Re-evaluating every formula on each edit: fails the dependents-only bullet and the 10k budget. Recursing into references without a graph: cycles hang. Teaching src.eval to pull dependencies itself: out of this intent's directories and against i3's 'read cells as stored' rule. Leaving ./engine on the constant echo: the hidden suite and this plan's see go through the CLI, so src/cli.py is in path scope and b1/b3 assert ./engine output. Checking only the library API: rejected once already — CLI cases are required.

## 4. Work items

### `wi-i4-recalc-1`: Dependency-order recalculate

Add src.recalc.recalculate for full workbook compute in dependency order with #REF! on cycles, and point ./engine at it (proven by library and CLI cases).

Status: landing (`169c884da938`)

**The passing review noted:** > pass review of wi-i4-recalc-1 @ 9cb2fb7 (attempt 1). Covers ac-b1 and ac-b3 only (b2/b4 are wi-i4-recalc-2).
> 
> verify (detached worktree at WI commit): tests/recalc/checks/b1_order.sh EXIT 0 (ok b1); tests/recalc/checks/b3_cycle.sh EXIT 0 (ok b3).
> 
> ac-b1 / b1 (dependency order): check green. recalculate builds deps and _topo_order at src/recalc/__init__.py:33-54,:189-211; evaluates via eval_mod.evaluate at :50-53. CLI wired: src/cli.py replaces compute_constants with recalculate at :9,:45. b1_order.sh exercises recalculate and ./engine (incl. --cell) for out-of-order and cross-sheet chains — addresses prior rejection.
> 
> ac-b3 / b3 (cycle → error, no hang): check green with engine timeout 5s. _cyclic_formulas SCC marks cycles as REF at :44-47,:147-186; remaining cells still compute. Matches {"error":"#REF!"}.
> 
> scope: machine last_diff is src/cli.py + src/recalc/__init__.py (both in path_scope). Note: commit also adds tests/recalc/__init__.py and tests/recalc/checks/b*.sh; law 9 drops check-file edits at land (flagged, not blocking — verify used those scripts; plan should already own the contract). Uses import src.eval as eval_mod (spy-friendly for b2). Incremental helpers present but unused without changed= (wi-2).
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/recalc/checks/b1_order.sh` | red | — |
| `ac-b3` | b3 | `tests/recalc/checks/b3_cycle.sh` | red | — |

### `wi-i4-recalc-2`: Incremental dirty recalc

Extend recalculate with changed+previous so an edit re-evaluates only dependents (via module-bound src.eval.evaluate), and keep a 10k chain under one second.

Status: accepted · depends on `wi-i4-recalc-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b2` | b2 | `tests/recalc/checks/b2_incremental.sh` | red | — |
| `ac-b4` | b4 | `tests/recalc/checks/b4_perf.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | chains of formula cells compute in dependency order | no landed check |
| not yet | b2 | an edit recomputes only its dependents | no landed check |
| not yet | b3 | a cycle gives an error | no landed check |
| not yet | b4 | 10,000 dependent cells recompute in under one second | no landed check |

## 5. Out of scope and risks

- **Out of scope:** functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Path scope:** `exp-b:src/recalc/**`, `exp-b:tests/recalc/**`, `exp-b:src/cli.py`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i4-recalc-1` | `impl-1@alebairos` |
| Reviewed `wi-i4-recalc-1` | `rev-1@alebairos` (passed attempt 1) |
| Implemented `wi-i4-recalc-2` | — |
| Reviewed `wi-i4-recalc-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

Landing pull request: [exp-b #9](https://github.com/alebairos/sheet-exp-b/pull/9)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 26 h 18 min so far
- Loops: 1 (D2 plan 1)
- Waste: 9 min
- Size: nothing landed yet
