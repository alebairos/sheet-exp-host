# Intent `i6-logic-text`

## 1. Outcome

> The 9 logic and information functions and the 8 text functions of SPEC.md compute as in Calc

Kind: Feature · State: in work · 2 work items · 2 bullets

## 2. What you will see

Logic and text formulas match Calc. =IF(TRUE,1,2) is 1 and =IF(0,"a","b") is "b"; =IF("x",1,2) is #VALUE!; =IFERROR(1/0,"x") is "x"; =AND(TRUE,1) is TRUE and =AND(TRUE,"x") is #VALUE!; =OR(FALSE,"x") and =NOT("x") are #VALUE!; =ISBLANK(Z9) is TRUE while =ISNUMBER("3") is FALSE and =ISNUMBER(TRUE) is TRUE and =ISTEXT("3") is TRUE; =ISERROR(1/0) is TRUE. =CONCATENATE("a",1) is "a1"; =LEFT("abcd",2) is "ab"; =MID("abcd",2,2) is "bc"; =LEN("ab") is 2; =UPPER("a") is "A"; =TRIM("  a  b  ") collapses internal space the way Calc does.

- No media: Library functions with no screen; expected values live in tests/functions/logic_text/checks/b*.sh

## 3. Approach

Ship both SPEC groups in src/functions/logic_text as one FUNCTIONS dict discovered by i0/i3. Two parallel WIs: logic and information (IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT, ISERROR) then text (CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM). IFERROR must see error Values (i3 leaves them in). IF, AND, OR and NOT coerce conditions through src.values.to_bool: non-zero numbers are true, 0 and blank are false, text is #VALUE! (same as Calc and the landed to_bool). Text functions coerce numbers through to_text where Calc does. Plan checks call evaluate on constant-cell books under tests/functions/logic_text/checks. ISNUMBER returns TRUE for Bool arguments (Calc treats booleans as 1/0; clarification).

- **Reuses:** src.eval.evaluate, Range, and registry discovery (i3); src.values to_bool/to_number/to_text/is_error and Error codes (i2); i0 FUNCTIONS package layout.
- **Removes:** none
- **Rejected:** Treating non-empty text as true in IF/AND/OR/NOT: Calc and to_bool give #VALUE! (prior plan rejected for this). Short-circuiting AND/OR by skipping argument evaluation in Python before the evaluator builds args: the evaluator already evaluated every argument. Putting these callables in src/eval: out of scope. One WI for all seventeen: over the size budget for parallel review.

## 4. Work items

### `wi-i6-logic-text-1`: Logic and information

Add IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT and ISERROR matching Calc (text conditions are #VALUE!).

Status: landed (`59e3019a2b6b`)

**The passing review noted:** > pass review of wi-i6-logic-text-1 @ bcc4ee0 (attempt 1). Covers ac-b1 only.
> 
> verify: tests/functions/logic_text/checks/b1_logic.sh EXIT 0 (ok b1), run against WI tip with plan/i6-logic-text check overlaid (check not in last_diff; lives on plan_oid eeb0040).
> 
> ac-b1 / b1 (IF IFERROR AND OR NOT ISBLANK ISNUMBER ISTEXT ISERROR match Calc): check green. Logic/info callables in src/functions/logic_text/__init__.py. IF/AND/OR/NOT coerce via to_bool (:33-78); text conditions yield VALUE. IFERROR returns fallback on Error Values (:44-48). ISNUMBER accepts Number and Bool per clarification (:85-88). ISBLANK/ISTEXT/ISERROR are type checks (:81-96). FUNCTIONS registers the nine names (:99-109). Registry discovery surfaces all nine.
> 
> scope: last_diff src/functions/logic_text/__init__.py in path_scope. No outside-scope paths. Text functions intentionally absent (wi-i6-logic-text-2).
> 
> No blocking findings.

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/functions/logic_text/checks/b1_logic.sh` | red | — |

### `wi-i6-logic-text-2`: Text functions

Add CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER and TRIM with Calc coercion and errors.

Status: in review by `rev-1@alebairos`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b2` | b2 | `tests/functions/logic_text/checks/b2_text.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | IF, IFERROR, AND, OR, NOT, ISBLANK, ISNUMBER, ISTEXT, ISERROR match Calc | `tests/functions/logic_text/checks/b1_logic.sh` — |
| not yet | b2 | CONCATENATE, LEFT, RIGHT, MID, LEN, UPPER, LOWER, TRIM match Calc, coercion and errors included | no landed check |

## 5. Out of scope and risks

- **Out of scope:** other functions; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/functions/logic_text/**`, `exp-b:tests/functions/logic_text/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i6-logic-text-1` | `impl-1@alebairos` |
| Reviewed `wi-i6-logic-text-1` | `rev-1@alebairos` (passed attempt 1) |
| Implemented `wi-i6-logic-text-2` | `impl-2@alebairos` |
| Reviewed `wi-i6-logic-text-2` | `rev-1@alebairos` |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-i6-logic-text-1`:

- `tests/functions/logic_text/checks/b1_logic.sh` +116 −0 (plan check)
- `src/functions/logic_text/__init__.py` +110 −0
- `tests/functions/logic_text/checks/b2_text.sh` +99 −0 (plan check)
- `tests/functions/logic_text/__init__.py` +1 −0 (plan check)
- `tests/functions/logic_text/checks/__init__.py` +0 −0 (plan check)

Landing pull request: [exp-b #11](https://github.com/alebairos/sheet-exp-b/pull/11)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 26 h 36 min so far
- Loops: 3 (D1 spec 1, D2 plan 2)
- Waste: 10 min
- Size: 110 lines (+110 −0, 1 file, ≤400; tests 0 lines); plan check files laid over by land, not in the size: +216 −0, 4 files
