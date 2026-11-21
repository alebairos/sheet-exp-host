#!/bin/sh
# b1 (plan a-v1-keep-work): undo and redo, several steps deep. On the served page (headless Chrome, real keys)
# with budget.json {A1: 1} open: type 2 into A1 and 3 into A2 (grid, Enter) and x into B1 (formula bar, Enter);
# click C5; Ctrl+Z three times restores B1 empty, then A2 empty, then A1 = 1; Ctrl+Y three times brings back
# A1 2, A2 3, B1 x; Save JSON then writes {A1: 2, A2: 3, B1: "x"}.
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_kw.mjs b1
