#!/bin/sh
# b2 (plan a-v1-grid-keys): clicking another cell while editing. On the served page (headless Chrome, real
# mouse and keys): select E1, type 5 (no Enter), click E3: E3 is selected and E1 shows 5; type 6, click G5: G5 is
# selected. Save JSON holds E1 5 and E3 6.
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_gk.mjs b2
