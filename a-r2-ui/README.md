# a-r2-ui: the walk-through in the browser

Open a workbook, edit a formula, see the error, fix it, save, all on the app page (`web/io/index.html`,
served by `python3 web/io/serve.py`). These screenshots come from headless Chromium driving a prototype
of the plan's page change (`prototype-index.html.diff`: the formula bar mounted above the grid and wired to
the open/save controller) through the plan's check, `tests/e2e/ui/checks/a_r2_b1_walkthrough.sh`.

1. `1-opened.png`: walk.json opened ({A1: 10, A2: 2, B1: "=A1/A2"}), B1 selected: the cell shows 5 and the
   formula bar shows `=A1/A2`.
2. `2-error.png`: `=A1/A3` typed in the bar + Enter (A3 is blank): B1 shows #DIV/0! in red and the bar shows
   the formula and the error's name.
3. `3-fixed.png`: `=A1/A2*3` + Enter: B1 shows 15 and the error is gone. Save JSON then downloads walk.json
   with `{"A1": 10, "A2": 2, "B1": "=A1/A2*3"}`.

Today, on main, the page has no formula bar: the walk-through stops at step 1 (you cannot see or edit B1's formula).
