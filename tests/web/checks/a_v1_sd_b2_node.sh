#!/bin/sh
# b2: ./test.sh runs the web parts' Node tests (grid, formula bar, open/save) and fails when one fails.
# In a fresh copy: ./test.sh must pass and show each Node suite run (not skipped); then, for each part,
# one failing test planted in its .test.mjs (only in a throwaway copy) must make ./test.sh fail.
set -eu
cd "$(dirname "$0")/../../.."
. tests/web/checks/a_v1_sd_common.sh
fail() { echo "FAIL b2: $*"; exit 1; }
command -v node >/dev/null || fail "Node.js is needed to run this check"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fresh_copy "$TMP/ok"
(cd "$TMP/ok" && ./test.sh) >"$TMP/ok.log" 2>&1 || { tail -30 "$TMP/ok.log"; fail "./test.sh fails on the product as is"; }
for part in grid formula_bar io; do
  grep -E "^test_[a-z_]+ \(tests\.web\.$part\.[^)]*\) \.\.\. ok$" "$TMP/ok.log" >/dev/null \
    || fail "./test.sh does not run tests/web/$part's Node tests (or skips them)"
done
for part in grid formula_bar io; do
  fresh_copy "$TMP/$part"
  printf '\nimport { test as plantedTest } from "node:test";\nplantedTest("planted failure", () => { throw new Error("planted"); });\n' \
    >>"$TMP/$part/tests/web/$part/$part.test.mjs"
  if (cd "$TMP/$part" && ./test.sh) >"$TMP/$part.log" 2>&1; then
    fail "a failing test in tests/web/$part/$part.test.mjs leaves ./test.sh green"
  fi
  grep -q planted "$TMP/$part.log" || fail "./test.sh failed with a planted $part failure, but not because of it"
  echo "a failing $part Node test fails ./test.sh"
done
echo "ok b2"
