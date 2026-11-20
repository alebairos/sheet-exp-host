# a-v1-cell-edit: what you will get

Screens taken in headless Chromium on the app page (`python3 web/io/serve.py`, `/io/index.html`) with the
checks' book.json (A1 10, A2 20, A3 =A1+A2, C1 =1/0, D1 =0.1+0.2, D2 text 007, D3 =ISTEXT(D2), E1 12.5, E2 hello).

- `0-today-F2-on-A3.png`, `0-today-after-+1-Enter.png`: main today. F2 on A3 opens the editor with 30,
  and End, +1, Enter leaves the text "30+1"; the formula is gone.
- `1-F2-on-A3.png`, `2-after-+1-Enter.png`: the prototype. F2 opens =A1+A2 in the cell; End, +1, Enter
  gives =A1+A2+1, which shows 31 (Calc's value).

`prototype.diff` (+22 -13 in web/grid/grid.js and web/io/index.html) is the throwaway prototype the checks
were run against: b1, b2, the product-suite check (with a stand-in test) and ./test.sh with every earlier
grid/io/bar/e2e check pass on it; on main b1 and b2 fail. The implementer writes the real change.

-- plan-a@alebairos
