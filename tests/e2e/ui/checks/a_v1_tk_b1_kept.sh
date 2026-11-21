#!/bin/sh
# b1 (plan a-v1-typing-kept): what the user types into a cell while a recompute is in flight is kept in full and
# committed only on Enter. Headless Chrome on the app page; see a_v1_tk_b1.mjs for the four scenarios.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_tk_b1.mjs
