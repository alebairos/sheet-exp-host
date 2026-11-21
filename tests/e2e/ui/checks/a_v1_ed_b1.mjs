// b1 in a real browser: 50%, 1e3, -2.5 and 'abc become the same values whether typed in a grid cell (A1:A4),
// typed in the formula bar (B1:B4) or read from a CSV (a second page load of entry.csv): 0.5, 1000, -2.5 and the
// text abc, as Calc enters typed input (a_v1_ed_calc.json "typed"). Save JSON shows what each cell holds.
import { CALC, fail, openPage, sleep } from "./a_v1_ed_page.mjs";

const TYPED = Object.keys(CALC.entry.typed);
const want = (t) => { const v = CALC.entry.typed[t]; return "text" in v ? v.text : v.number; };
const fails = [];
const check = (where, cells, refs) => TYPED.forEach((t, i) => {
  if (JSON.stringify(cells?.[refs[i]]) !== JSON.stringify(want(t))) fails.push(`${t} ${where} (${refs[i]}) holds ${JSON.stringify(cells?.[refs[i]])}, Calc enters ${JSON.stringify(want(t))}`);
});
// 1. Grid and bar, on a page with a one-cell workbook.
let pg = await openPage("entry.json", JSON.stringify({ sheets: { Sheet1: { H1: "x" } } }), ["H1", "x"]);
try {
  for (const [i, t] of TYPED.entries()) {
    await pg.click("A" + (i + 1));
    await pg.b.send("Input.dispatchKeyEvent", { type: "keyDown", key: t[0], text: t[0] });
    await pg.b.send("Input.dispatchKeyEvent", { type: "keyUp", key: t[0] });
    await pg.type(t.slice(1));
    await pg.key("Enter");
    await sleep(300);
    await pg.click("B" + (i + 1));
    await pg.inBar(t);
    await sleep(300);
  }
  await sleep(500);
  const cells = await pg.savedSheet();
  check("typed in a grid cell", cells, ["A1", "A2", "A3", "A4"]);
  check("typed in the formula bar", cells, ["B1", "B2", "B3", "B4"]);
} catch (e) { fails.push(String(e.stack || e)); }
// 2. CSV: the same four fields in one row.
const report = () => { for (const f of fails) console.log("FAIL " + f); if (!fails.length) console.log("ok b1: grid, formula bar and CSV enter 50%, 1e3, -2.5, 'abc alike (0.5, 1000, -2.5, abc)"); };
pg.b.close();
pg = await openPage("entry.csv", TYPED.join(",") + "\n", ["C1", "-2.5"]);
try { check("read from a CSV", await pg.savedSheet(), ["A1", "B1", "C1", "D1"]); } catch (e) { fails.push(String(e.stack || e)); }
report();
pg.done(fails.length ? 1 : 0);
