#!/bin/sh
# b3 (plan a-v1-grid-keys): leaving the formula bar by a click commits it. On the served page (headless
# Chrome, real mouse and keys): select E2, click the bar (#formula-bar input[aria-label=Formula]), type hello (no
# Enter), click E4: E4 is selected; select E5, type =1+1 in the bar, click F6: F6 is selected and E5 shows 2.
# Save JSON holds E2 "hello" and E5 "=1+1".
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_gk.mjs b3
