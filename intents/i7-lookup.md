# Intent `i7-lookup`

## 1. Outcome

> VLOOKUP, INDEX and MATCH compute as in Calc, exact and approximate, with #N/A and #REF! where Calc gives them

Kind: Feature · State: in work · 2 work items · 2 bullets

## 2. What you will see

Lookup formulas match Calc. =VLOOKUP(2,A1:C3,2,0) returns the exact row's column; approximate VLOOKUP on a sorted first column finds the last key ≤ the probe; a miss is #N/A; a column index past the table (or <1) is #VALUE! (Calc Err:502), not #REF!. =INDEX(A1:C3,2,3) picks a cell; out-of-range INDEX positions are #REF! (row/col 0 is #VALUE!); =MATCH(x,range,0) is exact and =MATCH(x,range,1) is sorted approximate. =VLOOKUP("3",A1:C4,2,0) and =MATCH("5",A1:A4,0) are #N/A.

- No media: Library functions with no screen; expected values live in tests/functions/lookup/checks/b*.sh

## 3. Approach

Implement VLOOKUP, INDEX and MATCH in src/functions/lookup as a FUNCTIONS dict for i0/i3 discovery. Two WIs (serial by wi_parallelism 1): VLOOKUP exact (range_lookup 0/FALSE) and sorted approximate (1/TRUE/default), then INDEX plus MATCH types 0 and 1. Arguments arrive as Range or Value per i3; walk Range.values() in row-major order to rebuild the table rectangle. VLOOKUP maps Calc Err:502 (bad column index) to #VALUE!; INDEX keeps #REF! for positions outside the range. Prefer LibreOffice Calc defaults when Excel differs. Plan checks under tests/functions/lookup/checks call evaluate on constant-cell books; their Calc pins were measured on LibreOffice 26.8. Exact text-vs-number lookups are #N/A (clarification: no arithmetic coercion in lookup compare).

- **Reuses:** src.eval.evaluate / Range / registry (i3); src.values Number/Text/Bool/Error/to_json (i2); i0 FUNCTIONS package layout.
- **Removes:** none
- **Rejected:** Calling an oversized VLOOKUP column #REF!: Calc gives Err:502, which this project maps to #VALUE! (prior plan rejected for promising #REF!). Linear scan that ignores sorted approximate semantics. Treating MATCH type -1 (descending) in this intent: the bullet names types 0 and 1 only. Putting helpers in src/eval: out of scope.

## 4. Work items

### `wi-i7-lookup-1`: VLOOKUP exact and approximate

Add VLOOKUP with exact and sorted approximate match, #N/A on miss, and #VALUE! for a bad column index as in Calc.

Status: landed (`d86b3a8c556a`)

**The passing review noted:** > pass review of wi-i7-lookup-1 @ ec6a1e9 (attempt 1). Covers ac-b1 only.
> 
> verify: tests/functions/lookup/checks/b1_vlookup.sh EXIT 0 (ok b1).
> 
> ac-b1 / b1 (VLOOKUP exact and sorted approximate match Calc): check green. VLOOKUP in src/functions/lookup/__init__.py: exact scan via compare (:92-99); approx last key ≤ probe (:101-113); bad col index → VALUE not REF (:85-86); miss → NA (:99,:112). range_lookup omitted/TRUE/nonzero ≈ approx (:57-68). FUNCTIONS registers VLOOKUP only (:116-118).
> 
> scope: last_diff src/functions/lookup/__init__.py in path_scope. Commit also adds tests/functions/lookup/__init__.py and b1_vlookup.sh (law 9 drops check edits at land — flagged). INDEX/MATCH intentionally absent (wi-i7-lookup-2).
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/functions/lookup/checks/b1_vlookup.sh` | red | — |

### `wi-i7-lookup-2`: INDEX and MATCH

Add INDEX and MATCH (types 0 and 1) matching Calc, with #N/A/#REF!/#VALUE! as pinned in the check.

Status: landing (`01a3fd67215e`)

**The passing review noted:** > pass review of wi-i7-lookup-2 @ 8bd812c (attempt 2). Covers ac-b2 only.
> 
> verify: tests/functions/lookup/checks/b2_index_match.sh EXIT 0 (ok b2). Spot-check b1_vlookup.sh EXIT 0 after merge onto landed VLOOKUP.
> 
> ac-b2 / b2 (INDEX and MATCH types 0 and 1): check green. INDEX/MATCH behavior preserved; FUNCTIONS now holds VLOOKUP plus INDEX and MATCH. Registry surfaces all three.
> 
> land-retry: attempt 1 was INDEX/MATCH-only and conflicted with wi-1. Attempt 2 merges main and combines FUNCTIONS — addresses the land failure.
> 
> scope: machine last_diff src/functions/lookup/__init__.py in path_scope. Merge also pulls already-landed main paths as parents — flagged for land awareness only.
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b2` | b2 | `tests/functions/lookup/checks/b2_index_match.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | VLOOKUP exact and sorted approximate match Calc | `tests/functions/lookup/checks/b1_vlookup.sh` — |
| not yet | b2 | INDEX and MATCH (types 0 and 1) match Calc, errors included | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/functions/lookup/**`, `exp-b:tests/functions/lookup/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i7-lookup-1` | `impl-1@alebairos` |
| Reviewed `wi-i7-lookup-1` | `rev-1@alebairos` (passed attempt 1) |
| Implemented `wi-i7-lookup-2` | `impl-1@alebairos`, `impl-2@alebairos` |
| Reviewed `wi-i7-lookup-2` | `rev-1@alebairos` (passed attempt 2) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-i7-lookup-1`:

- `src/functions/lookup/__init__.py` +118 −0
- `tests/functions/lookup/checks/b2_index_match.sh` +91 −0 (plan check)
- `tests/functions/lookup/checks/b1_vlookup.sh` +90 −0 (plan check)
- `tests/functions/lookup/__init__.py` +1 −0 (plan check)

Landing pull request: [exp-b #17](https://github.com/alebairos/sheet-exp-b/pull/17)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 26 h 55 min so far
- Loops: 4 (D1 spec 1, D2 plan 2, D6 landing 1)
- Waste: 20 min
- Size: 118 lines (+118 −0, 1 file, ≤400; tests 0 lines); plan check files laid over by land, not in the size: +182 −0, 3 files
