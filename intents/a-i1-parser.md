# Intent `a-i1-parser`

## 1. Outcome

> Formulas parse as Calc reads them: A1, $A$1, ranges, Sheet2!A1, every SPEC.md operator with Calc's precedence (including -A1^2 and 2^3^2), numbers, strings, booleans and function calls

Kind: Feature · State: Met · 1 work item · 3 bullets

## 2. What you will see

A Python API in src/parser: parse(formula) turns a cell's formula string (with its leading =) into a tree; show(tree) prints it as one canonical line, e.g. =-A1^2 shows (^ (neg A1) 2.0) and =2^3^2 shows (^ (^ 2.0 3.0) 2.0), the way Calc reads them; a malformed formula such as =1+ or =SUM(1, raises src.parser.ParseError and never anything else. Nothing changes in ./engine output yet: evaluation is the next intent.

- No media: A library API with no screen; its sample input and output are the cases in tests/parser/checks/a1_*.sh

## 3. Approach

The tree first, because every later part (eval, recalc, functions) walks it. A regex tokenizer (numbers incl. .5 and 1E3, "strings" with "" escapes, TRUE/FALSE, references A1/$A$1 with an optional Sheet2! or 'My Sheet'! prefix and an optional :B6 range end, identifiers, operators <> <= >= + - * / ^ & = < > % ( ) and , or ; as argument separator) and a recursive-descent parser in Calc's (LibreOffice's) order, loosest first: comparisons, &, + -, * /, ^, postfix %, unary minus/plus, primary. Every binary level is left-associative, so 2^3^2 is (2^3)^2 = 64 and -A1^2 is (-A1)^2, as Calc computes; unary plus is dropped as Calc does. Nodes: Number (float), Text, Bool, Error literal (#N/A ...), Ref (sheet, column, row, absolute flags), Range (two refs, one sheet), Name (an unknown identifier: #NAME? at evaluation, not a parse error), Call (upper-cased name, args; an omitted argument as in IF(A1,,1) is a Missing node), Unary, Percent, Binary. show() prints numbers as repr(float), text as a JSON string, refs upper-cased with $ and sheet kept, calls as (NAME args...), missing args as _, operators as (op left right), unary minus as (neg x), percent as (% x). Any malformed input raises ParseError, including too-deep nesting (RecursionError is caught). Unit tests go in tests/parser (with __init__.py so ./test.sh finds them); the three plan checks in tests/parser/checks are the contract.

- **Reuses:** The part directory src/parser and the unittest suite behind ./test.sh from a-i0-skeleton; SPEC.md's operator and reference list.
- **Removes:** none
- **Rejected:** A parser generator or third-party library: the repo is standard library only and must test from a clean clone. Right-associative ^ and unary minus below ^ (the usual math convention, and Excel's for ^): Calc does it the other way and Calc is the judge. Folding evaluation into the parser: evaluation is out of scope and its own intent; the tree keeps the two apart.

## 4. Work items

### `wi-a-i1-parser-1`: Formula parser as Calc reads it

Add src/parser: a tokenizer and recursive-descent parser that turns a formula string into a tree with Calc's precedence and associativity, plus a canonical printer and a ParseError for malformed input, so the evaluator (a later intent) has one agreed shape to walk.

Status: landed (`8f35744725a9`)

**The passing review noted:** > PASS. Verify rerun in a worktree of ca80587: all three checks green (ok b1/b2/b3), ./test.sh 21 tests OK; on plan base d190371 all three red (ImportError: no parse). No check file edited; all 5 paths inside src/parser and tests/parser.
> ac-a1-b1 (tests/parser/checks/a1_b1_refs.sh): ref token src/parser/parse.py:39-42 (optional quoted/plain sheet, $ flags, optional :cell end), _ref_token parse.py:76-98 (out-of-grid A1 like XFE1 becomes a Name, with a sheet it is a ParseError), show in src/parser/nodes.py:110-114,127-130 (upper-case, $ kept, sheet quoted when not plain, range end without sheet). Literals parse.py:36-38,119-122; Missing args parse.py:248-263.
> ac-a1-b2 (tests/parser/checks/a1_b2_precedence.sh): levels loosest-first parse.py:168-217 — compare, &, + -, * /, ^ (left-assoc loop :196-201), postfix % :203-208, unary - (unary + dropped) :210-217; so -A1^2 = (^ (neg A1) 2) and 2^3^2 = (^ (^ 2 3) 2) as Calc.
> ac-a1-b3 (tests/parser/checks/a1_b3_malformed.sh): tokenizer raises ParseError on unknown chars/bare sheet!/inf numbers parse.py:108-126; parser fail/expect :154-162 and trailing-token check :279-280; RecursionError mapped to ParseError :282-283; non-string input :271-272.
> Notes, not blocking: =A1:Sheet2!B2 and whole-column ranges (A:A, 1:1) are ParseErrors (design says a range is one sheet; columns not in SPEC list for this intent); -50% parses as (% (neg 50)) which evaluates the same as Calc; a sheet name containing '.' prints quoted, still round-trips. -- rev-a@alebairos

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-a1-b1` | b1 | `tests/parser/checks/a1_b1_refs.sh` | red | pass |
| `ac-a1-b2` | b2 | `tests/parser/checks/a1_b2_precedence.sh` | red | pass |
| `ac-a1-b3` | b3 | `tests/parser/checks/a1_b3_malformed.sh` | red | pass |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| PASS | b1 | references, ranges and sheet references parse | `tests/parser/checks/a1_b1_refs.sh` pass |
| PASS | b2 | operator precedence and associativity match Calc | `tests/parser/checks/a1_b2_precedence.sh` pass |
| PASS | b3 | a malformed formula is a parse error, not a crash | `tests/parser/checks/a1_b3_malformed.sh` pass |

## 5. Out of scope and risks

- **Out of scope:** evaluation; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-a:src/parser/**`, `exp-a:tests/parser/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-i1-parser-1` | `impl-a1@alebairos` |
| Reviewed `wi-a-i1-parser-1` | `rev-a@alebairos` (passed attempt 1) |
| Verdict (Met) | `alebairos` |

Product checks:

- `tests/parser/checks/a1_b1_refs.sh`: pass
- `tests/parser/checks/a1_b2_precedence.sh`: pass
- `tests/parser/checks/a1_b3_malformed.sh`: pass

Outcome report:

- **Built:** A formula parser in exp-a src/parser (landed via exp-a PR #3, one work item, first attempt, review passed). parse(formula) turns a cell formula into a tree and show(tree) prints it on one line. It reads formulas the way Calc does: =-A1^2 is (-A1)^2 and =2^3^2 is (2^3)^2 = 64. It handles A1, $A$1, ranges, Sheet2!A1 and 'My Sheet'!$A$1:B6, numbers, "strings" with "" escapes, TRUE/FALSE, % and function calls with skipped arguments (IF(A1,,1)). Unknown names are kept for #NAME? at evaluation. A malformed formula such as =1+ or =SUM(1, raises ParseError and never crashes. I re-ran these cases on main after the merge, and the full ./test.sh suite passes (36 tests). It follows the plan exactly: no extra dependencies, and evaluation is not included (that is the next intent). The engine's visible output does not change yet.
- **Advice:** Adopt. The intents that follow it (evaluator, recalc, functions) build on this tree. Watch Calc corner cases the checks do not cover yet, such as whole-column refs (A:A), named ranges and array literals {1,2}. If the hidden suite needs them, park them as follow-ups when the evaluator surfaces them.
- No media: A library API with no screen, as the plan said. Its sample inputs and outputs are the cases in tests/parser/checks/a1_*.sh

Files landed by `wi-a-i1-parser-1`:

- `src/parser/parse.py` +283 −0
- `src/parser/nodes.py` +143 −0
- `tests/parser/test_parser.py` +81 −0 (test)
- `tests/parser/checks/a1_b2_precedence.sh` +53 −0 (plan check)
- `tests/parser/checks/a1_b3_malformed.sh` +52 −0 (plan check)
- `tests/parser/checks/a1_b1_refs.sh` +51 −0 (plan check)
- `src/parser/__init__.py` +38 −1
- `tests/parser/__init__.py` +0 −0 (test)

Landing pull request: [exp-a #3](https://github.com/alebairos/sheet-exp-a/pull/3)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 8 h 28 min
- Loops: 0
- Waste: 0 min
- Size: 465 lines (+464 −1, 5 files, 401–1,000; tests 81 lines); plan check files laid over by land, not in the size: +156 −0, 3 files
