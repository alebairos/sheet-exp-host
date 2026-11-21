# a-v1-decimal-noise: outcome, run on the landed product

Run by gm-a@alebairos on exp-a main 4367e6e (after landing PR #32), 2026-11-21.

- `./test.sh`: OK
- `tests/eval/checks/a_v1_dn_b1_compare.sh`: ok 35 comparisons and subtractions match LibreOffice Calc
- `tests/cli/checks/a_v1_dn_b2_cli.sh`: ok 22 numbers print as LibreOffice reports them (0.3, 3.3, -34.52, ...)
- `tests/eval/checks/a_v1_dn_suite.sh`: ok the product's approximate-arithmetic tests run and pass (8)

## The judge's cases: engine vs LibreOffice (conflict: usefulness vs fidelity)

The usefulness judge failed this intent on `=100-99.99` and similar. I ran those cases in LibreOffice Calc 26.8.1.1 (headless over UNO, a fresh document, getValue/getString) and through `./engine`:

| Formula | LibreOffice value (shown) | ./engine |
| --- | --- | --- |
| =100-99.99 | 0.010000000000005116 (0.0100000000000051) | 0.0100000000000051 |
| =(100-99.99)=0.01 | FALSE | false |
| =IF(100-99.99=0.01,"ok","wrong") | wrong | "wrong" |
| =10.1-10 | 0.0999999999999996 | 0.0999999999999996 |
| =50-49.95 | 0.0499999999999972 | 0.0499999999999972 |
| =1000-999.9 | 0.100000000000023 | 0.100000000000023 |
| =ROUND(100-99.99,2)=0.01 | TRUE | true |
| =0.1+0.2 | 0.3 | 0.3 |
| =1.1*3 | 3.3 | 3.3 |
| =0.1+0.2=0.3 | TRUE (probe of the plan) | true |
| =(0.1+0.2)-0.3 | 0 (probe of the plan) | 0 |
| budget 1200-850.5-384.02 | -34.52 | -34.52 |

So the engine matches Calc on every case the judge raised: those differences are larger than Calc's 2^-48 tolerance, and Calc itself shows them.
An ordinary user would still expect 0.01 and TRUE. Fidelity says pass, usefulness says fail: the human settles it (val1 ADDENDUM: "fail the check with the case as evidence and say conflict").

Note: in a Calc window, a default-width column shows 0.01 for =100-99.99 (General format shortens to the column width); the CLI's JSON and the web grid show 15 digits.
