# a-v1-big-sheets: outcome, run on the landed product

Run by gm-a@alebairos on exp-a main a2293fd (after landing PR #30), 2026-11-21, Linux, CHROME=/usr/bin/chromium (headless), each check under a 300 s timeout:

- `tests/e2e/ui/checks/a_v1_bs_b1_scroll.sh`: ok b1: scrolled to L2001 (200111) and back in 218 wheel steps; median 49.2 ms, slowest 61.4 ms
- `tests/e2e/ui/checks/a_v1_bs_b2_keys.sh`: ok b2: keys reach A2001 and M2001, the view follows; B2001 := 5 gives M2001 10, M1 200101904 as in Calc
- `tests/e2e/ui/checks/a_v1_bs_suite.sh`: ok the product's big-sheet browser tests run and pass
- `./test.sh`: Ran 124 tests, OK (38.6 s)

These drive the served page (web/io/serve.py, /io/index.html) with real wheel and key events in Chromium, on a 2001-row x 12-column CSV, with Calc's values (LibreOffice 26.8.1.1) for the recomputed cells.

Note: the usefulness judge on this intent was answered "fail" by the human's delegate because it was not permitted to run the browser itself, not because of anything it saw in the product.
