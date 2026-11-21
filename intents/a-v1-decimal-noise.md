# Intent `a-v1-decimal-noise`

## 1. Outcome

> Decimal arithmetic looks and compares wrong. Observed: =0.1+0.2=0.3 gives FALSE where LibreOffice gives TRUE; =(0.1+0.2)-0.3 gives 5.55E-17 where Calc gives 0; the CLI prints 0.30000000000000004, 3.3000000000000003, and the budget's D5 as -34.51999999999998 (G19, G17; prior S2, S8). Expected: Calc's approximate equality and subtraction, and CLI numbers as Calc reports them. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: accepted · 2 work items · 2 bullets

## 2. What you will see

Decimal sums compare and subtract the way LibreOffice Calc does: =0.1+0.2=0.3 is TRUE, =(0.1+0.2)-0.3 is 0, =IF(0.1+0.2=0.3,"same","different") is "same", and a budget that should come out at -34.52 does. ./engine prints numbers as Calc reports them: 0.3 instead of 0.30000000000000004, 3.3 instead of 3.3000000000000003, and -34.52 instead of -34.51999999999998. Real differences are kept: =(1+1E-14)-1 is still 9.99200722162641E-15, as in Calc.

- [a-v1-decimal-noise/README.md](https://github.com/alebairos/sheet-exp-host/blob/ac01611b1836aa497ee30878d910d7c8d4e60b5d/a-v1-decimal-noise/README.md)
- [a-v1-decimal-noise/today-b2.txt](https://github.com/alebairos/sheet-exp-host/blob/ac01611b1836aa497ee30878d910d7c8d4e60b5d/a-v1-decimal-noise/today-b2.txt)
- [a-v1-decimal-noise/prototype-checks.txt](https://github.com/alebairos/sheet-exp-host/blob/ac01611b1836aa497ee30878d910d7c8d4e60b5d/a-v1-decimal-noise/prototype-checks.txt)
- [a-v1-decimal-noise/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/ac01611b1836aa497ee30878d910d7c8d4e60b5d/a-v1-decimal-noise/prototype.diff)

## 3. Approach

Cause, as read in src/eval and src/values and run on main. The operators use exact IEEE arithmetic: _arith does a + b and a - b, and = <> < > <= >= go through values.compare, which compares the doubles exactly. LibreOffice uses rtl::math's approximate helpers instead. Two doubles within 2**-48 of each other (relative) are equal. Subtracting two near-equal numbers of the same sign, or adding near-opposites, gives exactly 0. Separately, src/cli.py prints Python's shortest repr (0.30000000000000004), while Calc reports numbers to 15 significant digits.
Fix (WI 1, about 40 lines, as in the evidence prototype). src/values gains approx_equal(a, b) (a == b, or neither is 0 and |a-b| < |a|*2**-48 and < |b|*2**-48), approx_add and approx_sub. src/eval's + and - use them. A comparison of two numbers that compare unequal but are approx_equal counts as equal. values.compare itself, which the functions (criteria, MATCH) also use, is left alone: their Calc rules are another intent's. src/cli.py writes every float rounded to 15 significant digits (float(f"{x:.15g}")), so 0.1+0.2 prints 0.3. Internal values keep full precision, as Calc keeps them (=0.1+0.2 stays 0.30000000000000004 inside, and Calc stores the same). WI 2 adds tests/eval/test_approx.py.

Beliefs:
- ran: on main =0.1+0.2=0.3 is FALSE, =(0.1+0.2)-0.3 is 5.55e-17, and ./engine prints 0.30000000000000004, 3.3000000000000003 and -34.51999999999998 (the budget case 1200 - 850.5 - 384.02). Settled by a_v1_dn_b1_compare.sh and a_v1_dn_b2_cli.sh, both red on main (evidence today-b2.txt).
- ran: LibreOffice Calc 26.8.1.1 headless (a_v1_dn_probe.py, read from a_v1_dn_calc.json) gives TRUE and 0 for those cases. =1=1+1E-15 is TRUE but =1=1+1E-14 is FALSE, and (1+1E-14)-1 is 9.99200722162641E-15. Calc stores =0.1+0.2 as 0.30000000000000004 and shows 0.3, and stores the budget as -34.51999999999998, shown as -34.52. Settled by b1 and b2.
- memory: the rule is rtl::math::approxEqual with 2**-48, approxAdd and approxSub as LibreOffice's ScInterpreter uses them. ran: the prototype written from that rule passes all 35 Calc cases, including both sides of the 2**-48 edge. Settled by b1.
- ran: on the prototype (src +42 -3) ./test.sh and every earlier check script in the product (functions a-i5/a-i6/a-i7, engine e2e a-r1/a-r0, web) pass. Rounding output to 15 digits stays within the e2e suites' 1e-9 tolerance. Settled by the land test.
- memory: the hidden suite compares LibreOffice's numbers with a tolerance, so 15-digit output (Calc's own precision when shown) cannot lose a case that full doubles would win. Settled by the a-r0/a-r1 e2e checks staying green; not fully settleable before the hidden run.
- code: number-to-text formatting (CONCATENATE, &, LEN of numbers) is a-v1-number-text's and is not touched. Settled by: not claimed (out of scope).

Learned from RECORD.md and the overlapping pages: a-i5 already chose Calc's KahanSum order after fsum's last-bit difference (wi-a-i5-math-3) and flagged 'SUM differs from Calc in the last bits'. This plan follows the same principle (copy Calc's arithmetic, not Python's) for operators. Expected values come from running Calc, not memory: the review's G19 values were re-run, and the probe adds the 2**-48 edges that no review case covered. S8 (0.1+0.2 printed with noise while the grid shows 0.3) is fixed in the CLI only; the grid already formats to 15 digits. Overlap: a-v1-cli-input also changes src/cli.py (error handling and parsing input). This plan changes only the output step, and whichever lands second carries both. a-v1-text-rules, a-v1-eval-edges and a-v1-parse-fidelity also touch src/eval or src/values in other places.

- **Reuses:** src/eval's _arith and _COMPARE, src/values' Number and compare, and src/cli.py's output step; no new dependencies.
- **Removes:** Binary float noise in the CLI's output, and exact float comparison and subtraction in formulas' operators.
- **Rejected:** decimal.Decimal arithmetic: Calc computes in doubles, so Decimal would disagree with Calc elsewhere (a-i5 rejected it too). Rounding every result to 15 digits inside the engine: Calc keeps full doubles (it stores 0.30000000000000004), and later steps would drift from Calc. A fixed absolute epsilon such as 1e-9: wrong for large and small magnitudes, while Calc's rule is relative 2**-48. Changing values.compare for everyone: the functions' criteria and lookups have their own Calc rules, which are outside these bullets.

## 4. Work items

### `wi-a-v1-decimal-noise-1`: Calc's approximate arithmetic and plain CLI numbers

Formulas' + and - and their comparisons use LibreOffice's 2**-48 approximate equality, so =0.1+0.2=0.3 is TRUE and =(0.1+0.2)-0.3 is 0, and ./engine prints numbers to Calc's 15 significant digits (0.3, 3.3, -34.52) instead of binary noise.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-dn-b1` | b1 | `tests/eval/checks/a_v1_dn_b1_compare.sh` | red | — |
| `ac-dn-b2` | b2 | `tests/cli/checks/a_v1_dn_b2_cli.sh` | red | — |

### `wi-a-v1-decimal-noise-2`: Product tests for approximate arithmetic

Adds tests/eval/test_approx.py, run by ./test.sh, covering the equality and subtraction cases, the 2**-48 edges and the CLI's printed numbers, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-decimal-noise-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-dn-suite` | b1, b2 | `tests/eval/checks/a_v1_dn_suite.sh` | red | — |
| `ac-dn-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): using ./engine and the app page as shipped on an ordinary household budget and a few decimal calculations (=0.1+0.2, =1.1*3, a balance that should be -34.52, a check like =IF(total=expected,"ok","wrong")), does an ordinary user see the numbers and yes/no answers they would expect, with no 0.30000000000000004-style noise or a FALSE that should be TRUE? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | =0.1+0.2=0.3 is TRUE and =(0.1+0.2)-0.3 is 0, and comparisons and subtraction of nearly equal values match LibreOffice over a set of cases whose expected values come from running LibreOffice | no landed check |
| not yet | b2 | ./engine prints the budget, 0.1+0.2 and 1.1*3 cases with the values LibreOffice reports (0.3, 3.3, -34.52), not binary float noise | no landed check |

## 5. Out of scope and risks

- **Out of scope:** text formatting of numbers (a-v1-number-text)
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:src/eval/**`, `exp-a:src/cli.py`, `exp-a:src/values/**`, `exp-a:tests/eval/**`, `exp-a:tests/values/**`, `exp-a:tests/cli/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-decimal-noise-1` | — |
| Reviewed `wi-a-v1-decimal-noise-1` | — |
| Implemented `wi-a-v1-decimal-noise-2` | — |
| Reviewed `wi-a-v1-decimal-noise-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 2 h 50 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
