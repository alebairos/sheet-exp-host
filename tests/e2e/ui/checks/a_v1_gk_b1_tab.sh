#!/bin/sh
# b1 (plan a-v1-grid-keys): Tab and Shift+Tab. On the served page (headless Chrome, real keys) with A1 selected:
# Tab selects B1, Shift+Tab A1, and keyboard focus stays in #grid; typing 77 then Tab commits A1 = 77 and selects
# B1; 5 then Tab commits B1 = 5 and selects C1; 9 then Shift+Tab commits C1 = 9 and selects B1; ArrowDown then
# selects B2 (keys still reach the grid). Save JSON holds A1 77, B1 5, C1 9.
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_gk.mjs b1
