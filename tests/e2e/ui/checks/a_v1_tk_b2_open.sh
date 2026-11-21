#!/bin/sh
# b2 (plan a-v1-typing-kept): after a recompute returns, the cell being edited is still open with its text and
# caret, and focus stays in the grid. Headless Chrome on the app page; see a_v1_tk_b2.mjs for the two scenarios.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_tk_b2.mjs
