// b1 (plan a-v1-typing-kept): text typed into a cell while a recompute is in flight is kept in full and committed
// only on Enter. On the app page with A1 1, B1 =A1*2, C1 =A2*10: the user types 5 Enter in A2 (a recompute starts) and at once
// types a formula into A3 at 120 ms a key. The recompute (POST /compute, held by a_v1_tk_page.mjs) returns
// (1) mid-formula, (2) right after the first key, (3) after the whole formula but before Enter; and (4) on a real
// 2,000-row workbook (about 2 s to compute here), nothing held, "+0" typed until the recompute has come back (C1 shows 50).
// Each time: the editor holds every key typed, no recompute is sent before Enter, and after Enter A3 shows
// Calc's value (a_v1_tk_calc.json, from LibreOffice) and the bar shows the formula as typed.
import { readFileSync } from "node:fs";
import { openBook, press, type, editor, cell, fail, sleep } from "./a_v1_tk_page.mjs";
const CALC = Object.fromEntries(JSON.parse(readFileSync(new URL("./a_v1_tk_calc.json", import.meta.url))).cases.map((c) => [c.formula, c.number]));
const F = "=SUM(A1:A2)+B1";

async function scenario(name, book, releaseAt) {
  const p = await openBook(book);
  await p.js(`document.querySelector('#grid').focus()`);
  await press(p.b, "ArrowDown", 50);
  const before = p.computes;
  if (releaseAt !== "live") p.hold();
  await type(p.b, "5", 50); await press(p.b, "Enter", 50);
  if (releaseAt !== "live") await p.waitHeld(name);
  let typed = "";
  const key = async (ch) => {
    if (releaseAt === typed.length) await p.release();
    await press(p.b, ch, 120); typed += ch;
    const e = await p.js(editor);
    if (!e || e.ref !== "A3" || e.value !== typed)
      fail(`${name}: after typing ${JSON.stringify(typed)} into A3 the editor is ${JSON.stringify(e)} (focus ${await p.js("document.activeElement.tagName")})`);
  };
  for (const ch of F) await key(ch);
  if (releaseAt === "end") await p.release();
  if (releaseAt === "live") {   // keep typing until the real recompute has come back, then a little more
    const back = async () => (await p.js(cell("C1"))) === String(CALC["=A2*10"]);  // C1 =A2*10 changes only then
    let n = 0;
    for (; n < 38 && !(await back()); n++) { await key("+"); await key("0"); }
    if (!(await back())) fail(`${name}: the recompute did not come back while typing`);
    for (let k = 0; k < 2; k++, n++) { await key("+"); await key("0"); }
  }
  await sleep(300);
  if (p.computes !== before + 1) fail(`${name}: ${p.computes - before - 1} recompute(s) sent while A3 was still being typed`);
  const e = await p.js(editor);
  if (!e || e.value !== typed || !e.focused) fail(`${name}: before Enter the editor is ${JSON.stringify(e)}`);
  await press(p.b, "Enter", 50);
  const want = CALC[typed];
  if (want === undefined) fail(`${name}: no Calc value for ${typed}`);
  await p.until(`${name}: A3 after Enter`, cell("A3"), String(want), 150);
  await p.js(`document.querySelector('#grid td[data-ref="A3"]').click()`);
  await p.until(`${name}: the formula bar shows A3 as typed`, `document.querySelector('#formula-bar input')?.value ?? null`, typed);
  console.log(`ok ${name}: ${typed.length} keys kept, A3 = ${want}`);
  p.close();
}

const small = { sheets: { Sheet1: { A1: 1, B1: "=A1*2", C1: "=A2*10" } } };
const slow = { sheets: { Sheet1: { A1: 1, B1: "=A1*2", C1: "=A2*10" } } };
for (let r = 5; r < 2005; r++) Object.assign(slow.sheets.Sheet1, { ["D" + r]: r, ["E" + r]: r > 5 ? `=D${r}*2+E${r - 1}` : "=D5*2", ["F" + r]: `=SUM($D$5:D${r})` });
const runs = [["held, back mid-formula", small, 7], ["held, back after the first key", small, 1], ["held, back before Enter", small, "end"], ["2,000-row workbook, live", slow, "live"]];
for (const [name, book, at] of runs) {
  await scenario(name, book, at);
}
console.log("ok b1");
process.exit(0);
