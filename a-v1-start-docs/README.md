# a-v1-start-docs: evidence for the plan

- `today.txt`: main (f101426) today. Both plan checks fail. ./test.sh runs 75 tests and none of the
  web Node suites: `tests/web` has no `__init__.py`, so unittest never enters it (the formula bar and
  open/save wrappers exist but never ran; the grid has no wrapper). Run by hand, grid 7/7 and formula
  bar 6/6 pass, but open/save fails 1 of 9: its page test went stale when a-r2 added the formula bar
  import, and again when big-sheets made the grid a scroll box (more DOM than its fake element has).
- `prototype.diff` (about 20 lines outside tests): README.md gains "Use it in the browser" (the command,
  the URL, what you can do, Ctrl+C to stop); web/grid/README.md sends readers to that start and says
  its index.html is a demo with no engine; `tests/web/__init__.py`, `tests/web/grid/__init__.py` and
  `tests/web/grid/test_grid.py` (a copy of the formula bar's wrapper) register the suites; the open/save
  page test's fixture learns the formula bar import and the DOM the grid now uses. Its assertions are
  unchanged (still: one Delete is one compute, one key listener).
- On the prototype: both checks pass, ./test.sh runs 78 tests, all OK, the three web suites included;
  b1 also passes with port 8000 taken (it then gives serve.py another port, as README says).
