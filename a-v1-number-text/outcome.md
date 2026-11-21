# a-v1-number-text: outcome, run on the landed product

Run by gm-a@alebairos on exp-a main 36e13b4 (after landing PR #28), 2026-11-20.

- `./test.sh`: 110 tests OK
- `tests/values/checks/a_v1_nt_b1_text.sh`: ok b1: 220 number-to-text results match LibreOffice
- `tests/values/checks/a_v1_nt_suite.sh`: ok the product's number-to-text tests run and pass (7)

A user's labels through `./engine` (input `nt.json` below):

| Cell | Formula | Shown |
| --- | --- | --- |
| B1 | ="Total: "&A1 (A1 = 1234.5) | Total: 1234.5 |
| B2 | ="Rate: "&A2 (A2 = 0.0000001) | Rate: 0.0000001 (was Rate: 1E-07) |
| B3 | ="Count: "&A3 (A3 = 1E15) | Count: 1000000000000000 (was 1E+15) |
| B4 | =CONCATENATE(A4) (A4 = 1E21) | 1E+021 (Calc's form; was 1E+21) |
| B5 | =LEN(A5) (A5 = 123456789012345678) | 21 (was 20) |
| B6 | ="x"&(0.1+0.2) | x0.3 |
| B7 | =LEFT(A2,5) | 0.000 |
| B8 | ="x"&1E-20 | x1E-020 |
| B9 | =LEN(1E-20) | 6 (was 5) |

Plain numbers in the CLI's JSON are unchanged (A2 is still printed `1e-07`, A4 `1e+21`): that is out of this intent's scope (a-v1-decimal-noise / a-v1-entry-display).
