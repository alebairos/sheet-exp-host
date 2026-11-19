# Intent `i1-parser`

## 1. Outcome

> Formulas parse as Calc reads them: A1, $A$1, ranges, Sheet2!A1, every SPEC.md operator with Calc's precedence (including -A1^2 and 2^3^2), numbers, strings, booleans and function calls

Kind: Feature · State: awaiting the verdict · 1 work item · 3 bullets

## 2. What you will see

A Python API in src/parser: parse(formula) turns a cell's formula string (with its leading =) into a tree; show(tree) prints it as one canonical line, e.g. =-A1^2 shows (^ (neg A1) 2.0) and =2^3^2 shows (^ (^ 2.0 3.0) 2.0), the way Calc reads them; a malformed formula such as =1+ or =SUM(1, raises src.parser.ParseError and never anything else. Nothing changes in ./engine output yet: evaluation is the next intent.

- No media: A library API with no screen; its sample input and output are the cases in tests/parser/checks/b*.sh

## 3. Approach

The tree first, because every later part (eval, recalc, functions) walks it. A regex tokenizer (numbers incl. .5 and 1E3, "strings" with "" escapes, TRUE/FALSE, references A1/$A$1 with an optional Sheet2! or 'My Sheet'! prefix and an optional :B6 range end, identifiers, operators <> <= >= + - * / ^ & = < > % ( ) and , or ; as argument separator) and a recursive-descent parser in Calc's (LibreOffice's) order, loosest first: comparisons, &, + -, * /, ^, postfix %, unary minus/plus, primary. Every binary level is left-associative, so 2^3^2 is (2^3)^2 = 64 and -A1^2 is (-A1)^2, as Calc computes; unary plus is dropped as Calc does. Nodes: Number (float), Text, Bool, Error literal (#N/A ...), Ref (sheet, column, row, absolute flags), Range (two refs, one sheet), Name (an unknown identifier: #NAME? at evaluation, not a parse error), Call (upper-cased name, args; an omitted argument as in IF(A1,,1) is a Missing node), Unary, Percent, Binary. show() prints numbers as repr(float), text as a JSON string, refs upper-cased with $ and sheet kept, calls as (NAME args...), missing args as _, operators as (op left right), unary minus as (neg x), percent as (% x). Any malformed input raises ParseError, including too-deep nesting (RecursionError is caught). Unit tests go in tests/parser (with __init__.py so ./test.sh finds them); the three plan checks in tests/parser/checks are the contract.

- **Reuses:** The part directory src/parser and the unittest suite behind ./test.sh from i0-skeleton; SPEC.md's operator and reference list.
- **Removes:** none
- **Rejected:** A parser generator or third-party library: the repo is standard library only and must test from a clean clone. Right-associative ^ and unary minus below ^ (the usual math convention, and Excel's for ^): Calc does it the other way and Calc is the judge. Folding evaluation into the parser: evaluation is out of scope and its own intent; the tree keeps the two apart.

## 4. Work items

### `wi-i1-parser-1`: Calc formula parser

Add parse/show/ParseError in src/parser so formulas become a Calc-faithful tree and malformed input raises ParseError, proven by the three plan checks.

Status: landed (`37788f56e8dd`)

**The passing review noted:** > pass wi-i1-parser-1 (commit 67bb4c17651827e403e2eba494dd1d404f552369)
> 
> ac-b1 (b1: references, ranges and sheet references parse): PASS
> - reran tests/parser/checks/b1_refs.sh → exit 0 (ok b1)
> - tokenize/Parser sheet+ref: src/parser/__init__.py:131-210, 300-342 (A1/$A$1, Sheet2!, 'My Sheet'!, ranges)
> - parse/show entry: src/parser/__init__.py:344-357, 386+
> 
> ac-b2 (b2: operator precedence and associativity match Calc): PASS
> - reran tests/parser/checks/b2_precedence.sh → exit 0 (ok b2)
> - layers loosest-first: parse_expr..parse_pow src/parser/__init__.py:211-249 (^ left-assoc via while)
> - unary/percent below ^: src/parser/__init__.py:251+ (Calc: -A1^2 as (^ (neg A1) 2))
> 
> ac-b3 (b3: malformed formula is ParseError, not a crash): PASS
> - reran tests/parser/checks/b3_malformed.sh → exit 0 (ok b3)
> - ParseError class: src/parser/__init__.py:11-13; expect/consume raise ParseError:176-187
> - RecursionError → ParseError: src/parser/__init__.py:355-356
> 
> suite: ./test.sh → all tests passed (exit 0)
> 
> scope: paths under exp-b:src/parser/** and exp-b:tests/parser/** only
> - WI commit includes tests/parser/checks/*.sh (plan contract under tests/parser); law 9 drops check-file edits at land.
> - no path outside scope

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-b1` | b1 | `tests/parser/checks/b1_refs.sh` | red | — |
| `ac-b2` | b2 | `tests/parser/checks/b2_precedence.sh` | red | — |
| `ac-b3` | b3 | `tests/parser/checks/b3_malformed.sh` | red | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | references, ranges and sheet references parse | `tests/parser/checks/b1_refs.sh` — |
| not yet | b2 | operator precedence and associativity match Calc | `tests/parser/checks/b2_precedence.sh` — |
| not yet | b3 | a malformed formula is a parse error, not a crash | `tests/parser/checks/b3_malformed.sh` — |

## 5. Out of scope and risks

- **Out of scope:** evaluation; files outside this intent's directories; shared registration goes through what I0 set up
- **Non-functional:** matching Calc is the whole requirement here; speed is measured once, in i4-recalc
- **Path scope:** `exp-b:src/parser/**`, `exp-b:tests/parser/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-1@alebairos` |
| Certified | `gate-1@alebairos` |
| Implemented `wi-i1-parser-1` | `impl-1@alebairos` |
| Reviewed `wi-i1-parser-1` | `rev-1@alebairos` (passed attempt 1) |

Product checks: not recorded yet.

Outcome report: none yet.

Files landed by `wi-i1-parser-1`:

- `src/parser/__init__.py` +434 −0
- `tests/parser/checks/b2_precedence.sh` +53 −0 (plan check)
- `tests/parser/checks/b3_malformed.sh` +52 −0 (plan check)
- `tests/parser/checks/b1_refs.sh` +51 −0 (plan check)
- `tests/parser/__init__.py` +1 −0 (plan check)

Landing pull request: [exp-b #4](https://github.com/alebairos/sheet-exp-b/pull/4)

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 10 h 12 min so far
- Loops: 0
- Waste: 0 min
- Size: 434 lines (+434 −0, 1 file, 401–1,000; tests 0 lines); plan check files laid over by land, not in the size: +157 −0, 4 files
