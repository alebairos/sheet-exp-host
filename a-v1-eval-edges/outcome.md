# a-v1-eval-edges: outcome, run on the landed product

Run by gm-a@alebairos on exp-a main 36e13b4 (landing PR #29), 2026-11-20.

- `./test.sh`: OK (110 tests)
- `tests/eval/checks/a_v1_ee_b1_intersect.sh`: ok b1: implicit intersection matches LibreOffice on 16 formulas
- `tests/eval/checks/a_v1_ee_b2_branch.sh`: ok b2: self-references through untaken branches match LibreOffice on 20 formulas
- `tests/eval/checks/a_v1_ee_suite.sh`: ok the product's evaluation-edge tests run and pass (11)

Through `./engine` (sheet S, C2 = 3, C3 = 4):

| Cell | Formula | Result |
| --- | --- | --- |
| D2 | =C2:C3*10 (row 2) | 30 (was #VALUE!) |
| D3 | =C2:C3*10 (row 3) | 40 |
| D5 | =C2:C3 (row 5, outside the range) | #VALUE! (as in Calc) |
| A16 | =IF(TRUE,1,A16) | 1 (was Err:522) |
| B8 / B9 | =IFERROR(B9,0) / =B8 | 0 / Err:522 (as in Calc) |
| E1 / E2 | =E2 / =E1 | Err:522 / Err:522 (a real cycle still shows) |
| F1 | =IF(F2="",0,F1+1) | 0 |
| G1 | =SUM(C2:C3) | 7 (functions unchanged) |

Whole book computed in 0.06 s.

Gap that stays open, as the reviewer said: a range passed straight to a function that takes one value is not intersected.
With C2 = -3, `=ABS(C2:C3)` in row 2 gives #VALUE! (Calc 3). Inside an operator it works: `=IF(C2:C3<0,"neg","pos")` in row 2 gives "neg".
