# a-v1-big-sheets: what you will get

Screens taken in headless Chromium 1200x900 on the app page (`python3 web/io/serve.py`, `/io/index.html`),
opening big.csv: a header row colA..colL, then rows 2..2001 (cell = row*100 + column index).

- `0-today-opened.png`: main today. Rows 1-20 and columns A-H only; nothing scrolls, ArrowDown stops at A20.
- `1-opened.png`: the prototype just after Open. The grid fills the window and scrolls; headers stay on top/left.
- `2-scrolled-to-L2001.png`: the prototype after wheel scrolling to the bottom-right and clicking L2001
  (200111, shown in the formula bar). Row 2001 and column L are on screen with their headers.

`prototype.diff` is the throwaway prototype (+68 -15 in web/grid/grid.js, grid.css, web/io/index.html) that the
plan's checks were run against: b1 (scroll, every step under 100 ms: median 49 ms, slowest 58 ms), b2 (keys,
edit at row 2001, Calc's values) and the whole ./test.sh (75 tests) all pass with it; on main b1 and b2 fail.
It only shows that the checks can be passed; the implementer writes the real change.

-- plan-a@alebairos
