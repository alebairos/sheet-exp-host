#!/bin/sh
# b2 (plan a-v1-keep-work): leaving with unsaved edits asks first. On the served page (headless Chrome): a
# reload with no edits opens no dialog; after typing 7 into A1, a reload opens a beforeunload confirmation
# (DevTools Page.javascriptDialogOpening, type beforeunload); staying keeps A1 = 7; after Save JSON a reload
# opens no dialog again.
# The browser: $CHROME, else google-chrome, google-chrome-stable, chromium or chromium-browser; none is a FAIL.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_kw.mjs b2
