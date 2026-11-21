// b2 (plan a-v1-typing-kept): after a recompute returns, the cell being edited is still open with its text and
// caret, and focus stays in the grid. On the app page with A1 1, B1 =A1*2, C1 =A2*10, the user types 5 Enter in
// A2 (its recompute is held by a_v1_tk_page.mjs), then edits A3; the recompute is let through and comes back
// (C1 shows 50). (1) "=A1+B", caret moved one left: after the recompute the editor is open on A3 with "=A1+B",
// caret 4, focused; typing "2*" lands at the caret, End then "1" makes "=A1+2*B1", Enter: A3 shows Calc's 5.
// (2) "xyz": after the recompute the editor is still open with "xyz"; Escape cancels it: A3 stays empty, no
// recompute is sent, and the keyboard is still in the grid. Calc's values: a_v1_tk_calc.json (LibreOffice).
import { readFileSync } from "node:fs";
import { openBook, press, type, editor, cell, focusIn, fail, sleep } from "./a_v1_tk_page.mjs";
const CALC = Object.fromEntries(JSON.parse(readFileSync(new URL("./a_v1_tk_calc.json", import.meta.url))).cases.map((c) => [c.formula, c.number]));
const book = { sheets: { Sheet1: { A1: 1, B1: "=A1*2", C1: "=A2*10" } } };

async function start(name, text, moves = []) {
  const p = await openBook(book);
  await p.js(`document.querySelector('#grid').focus()`);
  await press(p.b, "ArrowDown", 50);
  p.hold();
  await type(p.b, "5", 50); await press(p.b, "Enter", 50);
  await p.waitHeld(name);
  await type(p.b, text, 120);
  for (const k of moves) await press(p.b, k, 120);
  const before = await p.js(editor);
  await p.release();
  await p.until(`${name}: the recompute comes back (C1)`, cell("C1"), String(CALC["=A2*10"]));
  await sleep(200);
  const after = await p.js(editor), where = await p.js(focusIn);
  if (JSON.stringify(after) !== JSON.stringify(before) || where !== "grid")
    fail(`${name}: before the recompute came back the editor was ${JSON.stringify(before)}; after it, ${JSON.stringify(after)}, focus in ${where}`);
  return p;
}

{ // (1) text and caret kept, typing goes on at the caret
  const name = "caret";
  const p = await start(name, "=A1+B", ["ArrowLeft"]);
  const e0 = await p.js(editor);
  if (e0.value !== "=A1+B" || e0.caret[0] !== 4 || e0.caret[1] !== 4 || !e0.focused) fail(`${name}: editor ${JSON.stringify(e0)}, wanted "=A1+B" with the caret at 4`);
  await type(p.b, "2*", 120);
  const e1 = await p.js(editor);
  if (!e1 || e1.value !== "=A1+2*B" || e1.caret[0] !== 6) fail(`${name}: typing after the recompute gave ${JSON.stringify(e1)}, wanted "=A1+2*B" with the caret at 6`);
  await press(p.b, "End", 120); await type(p.b, "1", 120); await press(p.b, "Enter", 50);
  await p.until(`${name}: A3 after Enter`, cell("A3"), String(CALC["=A1+2*B1"]), 150);
  console.log("ok the editor kept =A1+B and its caret through the recompute; A3 = " + CALC["=A1+2*B1"]);
  p.close();
}
{ // (2) still a live edit: Escape cancels, nothing was committed
  const name = "escape";
  const p = await start(name, "xyz");
  const n = p.computes;
  await press(p.b, "Escape", 200);
  await sleep(300);
  const e = await p.js(editor), a3 = await p.js(cell("A3")), where = await p.js(focusIn);
  if (e || a3 !== "" || p.computes !== n || where !== "grid")
    fail(`${name}: after Escape the editor is ${JSON.stringify(e)}, A3 shows ${JSON.stringify(a3)}, ${p.computes - n} recompute(s) sent, focus in ${where}`);
  console.log("ok the edit stayed open through the recompute and Escape cancelled it");
  p.close();
}
console.log("ok b2");
process.exit(0);
