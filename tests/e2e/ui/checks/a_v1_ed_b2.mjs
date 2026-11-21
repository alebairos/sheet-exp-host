// b2 in a real browser: the grid shows numbers as Calc's General format draws them in a standard-width column.
// Opens a workbook holding a_v1_ed_calc.json's 75 numbers in A1:D20 (down each column) and reads each cell's text,
// halves at the cut included (Calc rounds them away from zero: 1234567890.5 shows 1234567891).
import { CALC, openPage, cellText } from "./a_v1_ed_page.mjs";

const refOf = (i) => "ABCD"[Math.floor(i / 20)] + ((i % 20) + 1);
const text = `{"sheets": {"Sheet1": {${CALC.shown.map(([x], i) => `"${refOf(i)}": ${x}`).join(", ")}}}}`;
const pg = await openPage("numbers.json", text, ["A7", CALC.shown[6][1]]);
const fails = [];
try {
  for (const [i, [x, shown]] of CALC.shown.entries()) {
    const got = await pg.js(cellText(refOf(i)));
    if (got !== shown) fails.push(`${x} in ${refOf(i)} shows ${JSON.stringify(got)}, Calc shows ${JSON.stringify(shown)}`);
  }
} catch (e) { fails.push(String(e.stack || e)); }
for (const f of fails) console.log("FAIL " + f);
if (!fails.length) console.log(`ok b2: ${CALC.shown.length} numbers show as Calc's General format in a standard column`);
pg.done(fails.length ? 1 : 0);
