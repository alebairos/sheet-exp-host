// a-v1-sheet-tabs checks in a real browser with real clicks and keys, on web/io/index.html as web/io/serve.py
// serves it, order.json (a_v1_st_calc.json "book": Prices and Order, each reading the other) opened. b1 or b2.
import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { openPage, cellText, sleep } from "./a_v1_st_page.mjs";

const CALC = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "a_v1_st_calc.json"), "utf8"));
const which = process.argv[2];
const pg = await openPage("order.json", JSON.stringify({ sheets: CALC.book }), ["A1", "Pen"]);
const fails = [];
const tabs = `[...document.querySelectorAll('#sheet-tabs [role=tab]')].map((t) => t.textContent.trim() + (t.getAttribute("aria-selected") === "true" ? "*" : ""))`;
const sheetName = `document.getElementById("sheet-name")?.textContent.trim() ?? null`;
try {
  if (which === "b1") {
    const t = await pg.js(tabs);
    if (JSON.stringify(t) !== JSON.stringify(["Prices*", "Order"])) fails.push("the tabs are " + JSON.stringify(t) + ", wanted Prices (selected) and Order");
    await pg.tab("Order");
    await pg.until("after clicking the Order tab, A1 shows Order's Pens", cellText("A1"), "Pens", 30);
    await pg.until("Order's B3 shows Calc's total", cellText("B3"), CALC.before.Order.B3, 30);
    await pg.until("the Order tab is the selected one", `JSON.stringify(${tabs})`, JSON.stringify(["Prices", "Order*"]), 10);
    await pg.click("B2");
    await pg.until("the formula bar names the sheet (#sheet-name)", sheetName, "Order", 10);
    await pg.tab("Prices");
    await pg.until("back on Prices, A1 shows Pen", cellText("A1"), "Pen", 30);
    await pg.until("Prices' D1 shows Calc's sum of the order", cellText("D1"), CALC.before.Prices.D1, 30);
    await pg.until("the formula bar names Prices", sheetName, "Prices", 10);
  } else if (which === "b2") {
    await pg.tab("Order");
    await pg.until("Order is shown", cellText("A1"), "Pens", 30);
    await pg.click("B1"); await pg.key("5"); await pg.key("Enter"); await sleep(600);
    await pg.until(`Order!B3 recomputes to Calc's ${CALC.after_Order_B1_5.Order.B3}`, cellText("B3"), CALC.after_Order_B1_5.Order.B3, 30);
    await pg.tab("Prices");
    await pg.until(`Prices!D1 (reading Order) recomputes to Calc's ${CALC.after_Order_B1_5.Prices.D1}`, cellText("D1"), CALC.after_Order_B1_5.Prices.D1, 30);
    await pg.until("Prices!B1 is untouched", cellText("B1"), "10.5", 10);
    const saved = await pg.savedSheet();
    const want = { Prices: CALC.book.Prices, Order: { ...CALC.book.Order, B1: 5 } };
    if (JSON.stringify(saved) !== JSON.stringify(want)) fails.push("Save JSON writes " + JSON.stringify(saved) + ", wanted " + JSON.stringify(want));
  }
} catch (e) { fails.push(String(e.stack || e)); }
for (const f of fails) console.log("FAIL " + f);
if (!fails.length) console.log(`ok ${which}`);
pg.done(fails.length ? 1 : 0);
