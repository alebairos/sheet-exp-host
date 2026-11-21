# a-v1-typing-kept: evidence for the plan

- `today.txt`: main fails both checks. When a recompute comes back while a cell is being typed into, the page
  redraws the grid (grid.setState -> draw -> innerHTML), which throws the open editor away; focus falls to BODY,
  so the next keys go nowhere and what was typed is lost (the review's G4/S14).
- `prototype.diff` (18 lines in web/grid/grid.js, plus a product test): setState keeps an open edit. It notes the
  editor, its cell and caret, redraws, and puts the same input back into the cell with its caret and focus. The
  edit still ends only on Enter (commit) or Escape (cancel).
- With it: b1 (4 scenarios: back mid-formula, after the first key, before Enter, and a live 2,000-row workbook
  that takes about 2 s to compute), b2 (caret and Escape) and the suite check pass; ./test.sh runs 77 tests, OK;
  every other web and UI check (a9, a10, a11, a-r0, a-r2, big-sheets) still passes.
- How the race is made repeatable: the checks hold the page's POST /compute with the DevTools Fetch domain and let
  it through at a chosen keystroke. The product is not changed for the test; the live scenario uses no hold.
