// b2 in a real browser: the grid shows numbers as Calc's General format draws them in a standard-width column.
// Opens a workbook holding a_v1_ed_calc.json's 34 numbers in A1:A17 and B1:B17 and reads each cell's text.
import { CALC, openPage, cellText } from "./a_v1_ed_page.mjs";

const refOf = (i) => (i < 17 ? "A" : "B") + ((i % 17) + 1);
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
