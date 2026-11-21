// b1, values kept (plan a-v1-entry-display, after gate review 2): what a user types into a grid cell is kept as
// Calc keeps it, whatever the grid draws. On the shipped page, 123456789012, 3.141592653589793, '123 and 'TRUE
// are typed into A1:A4. Then: Save JSON holds exactly Calc's values (a_v1_ed_keep.json: the two numbers to the
// last digit, the texts "123" and "TRUE"); Save CSV writes the two numbers in full; F2 opens each cell with text
// that reads back as the same value ('123 and 'TRUE as Calc's input line shows them), and Enter changes nothing.
import { readFileSync, existsSync, rmSync, mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { openPage, sleep, editor } from "./a_v1_ed_page.mjs";
const KEEP = JSON.parse(readFileSync(new URL("./a_v1_ed_keep.json", import.meta.url))).typed;
const TYPED = Object.keys(KEEP), REFS = ["A1", "A2", "A3", "A4"];
const want = (t) => ("number" in KEEP[t] ? KEEP[t].number : KEEP[t].text);
const fails = [];
const pg = await openPage("keep.json", JSON.stringify({ sheets: { Sheet1: { H1: "x" } } }), ["H1", "x"]);
const press = async (key, code) => { for (const type of ["rawKeyDown", "keyUp"]) await pg.b.send("Input.dispatchKeyEvent", { type, key, windowsVirtualKeyCode: code }); await sleep(100); };
const compare = (cells, when) => TYPED.forEach((t, i) => {
  if (cells?.[REFS[i]] !== want(t)) fails.push(`${t} typed in ${REFS[i]}: ${when} the workbook holds ${JSON.stringify(cells?.[REFS[i]])}, Calc keeps ${JSON.stringify(want(t))}`);
});
try {
  for (const [i, t] of TYPED.entries()) {
    await pg.click(REFS[i]);
    await pg.b.send("Input.dispatchKeyEvent", { type: "keyDown", key: t[0], text: t[0] });
    await pg.b.send("Input.dispatchKeyEvent", { type: "keyUp", key: t[0] });
    await pg.type(t.slice(1));
    await press("Enter", 13);
    await sleep(400);
  }
  compare(await pg.savedSheet(), "after typing,");
  // F2 then Enter on each cell: the editor's text reads back as the same value, and nothing changes.
  for (const [i, t] of TYPED.entries()) {
    await pg.click(REFS[i]);
    await press("F2", 113);
    const text = await pg.js(editor);
    const ok = "text" in KEEP[t] ? text === KEEP[t].input_line : text !== null && Number(text) === want(t);
    if (!ok) fails.push(`F2 on ${REFS[i]} (${t}) opens the editor with ${JSON.stringify(text)}`);
    await press("Enter", 13);
    await sleep(400);
  }
  compare(await pg.savedSheet(), "after F2 and Enter on each cell,");
  // Save CSV, last (its download goes to a folder of this check's own): column A of rows 1 and 2.
  const dir = mkdtempSync(join(tmpdir(), "a-v1-ed-csv-"));
  await pg.b.send("Browser.setDownloadBehavior", { behavior: "allow", downloadPath: dir });
  await pg.js(`document.getElementById("save-csv").click()`);
  const out = join(dir, "keep.csv");
  for (let n = 0; n < 50 && !existsSync(out); n++) await sleep(100);
  await sleep(200);
  const rows = existsSync(out) ? readFileSync(out, "utf8").split(/\r?\n/) : [];
  rmSync(dir, { recursive: true, force: true });
  for (const [i, t] of TYPED.slice(0, 2).entries()) {
    const field = rows[i]?.split(",")[0];
    if (field !== String(want(t)))
      fails.push(`Save CSV writes ${JSON.stringify(field)} for ${t} in ${REFS[i]}, not the number in full (${want(t)})`);
  }
} catch (e) { fails.push(String(e.stack || e)); }
for (const f of fails) console.log("FAIL " + f);
if (!fails.length) console.log("ok b1 (kept): 123456789012, 3.141592653589793, '123 and 'TRUE are kept through Save JSON, Save CSV and F2+Enter");
pg.done(fails.length ? 1 : 0);
