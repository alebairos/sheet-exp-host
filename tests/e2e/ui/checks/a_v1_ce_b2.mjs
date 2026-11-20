// b2 in a real browser with real keys and mouse: on each kind of cell (formula A3, error C1 =1/0, formula with a
// long decimal D1 =0.1+0.2, number-like text D2 "007", number E1, text E2), open the in-cell editor (F2, or a real
// double-click) and close it without typing (Enter, or Escape). After each of those 24 round trips every cell
// shows what Calc shows for the untouched workbook and Save JSON writes the workbook exactly as it was opened.
import { CALC, fail, openPage, cellText, sleep } from "./a_v1_ce_page.mjs";

const { until, done, click, key, savedSheet, editor } = await openPage();
try {
  for (const ref of ["A3", "C1", "D1", "D2", "E1", "E2"]) {
    for (const [open, close] of [["F2", "Enter"], ["F2", "Escape"], ["double-click", "Enter"], ["double-click", "Escape"]]) {
      const what = `${open} then ${close} on ${ref} (${JSON.stringify(CALC.book[ref])}) without typing`;
      await click("H10");
      await click(ref);
      if (open === "F2") await key("F2"); else await click(ref, 2);
      await until(`${what}: the in-cell editor opens`, `(${editor}) !== null`, true, 30);
      await key(close);
      await until(`${what}: the editor closes`, `(${editor}) === null`, true, 30);
      await sleep(300);
      for (const [r, shown] of Object.entries(CALC.shown)) await until(`${what}: ${r} shows Calc's value`, cellText(r), shown, 20);
      const saved = await savedSheet();
      if (JSON.stringify(saved) !== JSON.stringify(CALC.book)) fail(`${what}: Save JSON writes ${JSON.stringify(saved)}, wanted ${JSON.stringify(CALC.book)}`);
    }
  }
  console.log("ok b2: 24 open-and-close round trips (F2 or double-click, Enter or Escape) change no cell");
  done(0);
} catch (e) { console.log("FAIL " + (e.stack || e)); done(1); }
