# Intent `a-v1-entry-display`

## 1. Outcome

> The same input gives different results depending on where I type it, and the grid shows numbers unlike Calc. Observed: 50% typed in the grid is stored as text (=A1*2 gives #VALUE!), in the formula bar it is 0.5, in a CSV it is text; =10^15+1 shows as 1E+15 in the grid (the CLI gives 1000000000000001), 1E-7 shows 1E-07 (G12, G16; prior S23, S25). Expected, as in Calc: one entry rule for grid, bar and CSV (50% is the number 0.5, shown 50%), and numbers shown as Calc's General format shows them. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: accepted · 3 work items · 2 bullets

## 2. What you will see

Typing behaves the same everywhere. 50% typed in a grid cell, in the formula bar or found in a CSV is the number 0.5 (so =A1*2 is 1, not #VALUE!), 1e3 is 1000, -2.5 is -2.5, and 'abc is the text abc, as when you type them in Calc. Note: the cell then shows 0.5, not 50% as the outcome's Expected says; Calc shows 50% because it also applies a percent format on entry, and the product has no number formats (out of scope here). The grid draws numbers the way Calc's General format draws them in a normal-width column: 1234567890123456 shows 1.23457E+15, 0.0000001 shows 0.0000001 (not 1E-07), 1/3 shows 0.333333333, 123456789.123 shows 123456789.1, and 1234567890.5 shows 1234567891 (Calc rounds halves away from zero). Calc's own drawing of the 75 numbers is in calc-shown.pdf. What you typed is always kept: a long number may be drawn shortened to fit its column (123456789012 as 1.23457E+11), but the cell, Save JSON, Save CSV and the editor (F2) keep every digit, and '123 stays text.

- [a-v1-entry-display/README.md](https://github.com/alebairos/sheet-exp-host/blob/5694acb566274c943c2b97799a4c58d7069e8194/a-v1-entry-display/README.md)
- [a-v1-entry-display/calc-shown.pdf](https://github.com/alebairos/sheet-exp-host/blob/5694acb566274c943c2b97799a4c58d7069e8194/a-v1-entry-display/calc-shown.pdf)
- [a-v1-entry-display/today-checks.txt](https://github.com/alebairos/sheet-exp-host/blob/5694acb566274c943c2b97799a4c58d7069e8194/a-v1-entry-display/today-checks.txt)
- [a-v1-entry-display/general_model.py](https://github.com/alebairos/sheet-exp-host/blob/5694acb566274c943c2b97799a4c58d7069e8194/a-v1-entry-display/general_model.py)
- [a-v1-entry-display/prototype-keep.diff](https://github.com/alebairos/sheet-exp-host/blob/5694acb566274c943c2b97799a4c58d7069e8194/a-v1-entry-display/prototype-keep.diff)

## 3. Approach

Cause, as read in the code and run on main. Three parsers decide what typed text means. The grid's parseInput (web/grid/grid.js) knows numbers and TRUE/FALSE but not 50% or a leading apostrophe. The formula bar's parseInput (web/formula_bar/formula_bar.js) knows both. parseCSV (web/io/io.js) reuses the grid's. So 50% and 'abc differ by where they were typed (G12/S23). For display, grid.js formatNumber writes up to 15 significant digits and switches to E-notation below 1E-4 or from 1E15, regardless of width. Calc's General format instead fits the number to the column width: fewer decimals, or a shorter mantissa in E-notation (G16/S25).
Fix. WI 1: the grid's parseInput follows the bar's rule (a leading ' makes text and is dropped; n% is n/100; numbers, TRUE/FALSE, otherwise text), so the grid and parseCSV, which calls it, agree with the bar. One rule can live in grid.js and the bar can keep its local copy pinned by the same check, as a-i10 chose. WI 2: grid.js display/formatNumber renders General as Calc does in a standard-width column. Use the full General text when it fits a width budget of about 62 pt in Liberation Sans 10 (digits 5.56, '.' 2.78, '-' 3.33, 'E' 6.67, '+' 5.84). Otherwise use the fitting decimal or E form that keeps more significant digits, preferring decimal when it is exact. Digits cut by the column round half away from zero, as Calc rounds (1234567890.5 shows 1234567891, 0.1234567895 shows 0.12345679). Calc's 3-digit positive exponent from 1E+16 applies only to the full text. The evidence's general_model.py implements exactly this and matches all 75 of Calc's texts. WI 3 adds tests/e2e/ui/test_entry_display.py.

Beliefs:
- ran: on main, 50% and 'abc typed in a grid cell or read from CSV stay the text "50%" and "'abc", while the bar gives 0.5 and abc. Many of the 75 numbers draw unlike Calc (1.23456789012346E+15 for Calc's 1.23457E+15, 1E-07 for 0.0000001, 0.333333333333333 for 0.333333333, 1E+20 for 1E+020, ...). Settled by a_v1_ed_b1_entry.sh and a_v1_ed_b2_display.sh, both red on main (evidence today-checks.txt).
- ran: LibreOffice Calc 26.8.1.1 enters typed 50%, 1e3, -2.5 and 'abc as 0.5, 1000, -2.5 and the text abc (a_v1_ed_probe.py, read from a_v1_ed_calc.json). Calc's default CSV import gives 0.5, 1000 and -2.5 too, but keeps 'abc as the text "'abc". Settled by b1.
- human: the bullet asks for text abc from a CSV as well, which differs from Calc's import ('abc). The plan follows the bullet. The HITL's delegate confirmed this on the last spec review ('Treat 'abc from a CSV as the text abc so one rule covers grid, bar and CSV'), and that 50% showing as 0.5 is fine. Settled by that answer.
- ran: Calc draws General numbers in the standard column (2.258 cm) as the PDF export shows them (evidence calc-shown.pdf). Those 75 texts are b2's expected values. Since the replan they include 20 halves where the column cuts digits (integer, decimal and E cuts) and 21 held-out magnitudes, all drawn by Calc. The full, width-free text (getString) differs, e.g. =10^15+1 is 1000000000000001 in full but 1E+15 in the column, so the grid's 1E+15 there is already right. Settled by b2.
- ran: a width-budget model (evidence general_model.py) reproduces all 75. Its glyph widths (from memory of Liberation Sans metrics) were set on the first 34. On the 41 added in the replan, the only miss was rounding: Python's half-to-even against Calc's half away from zero, which the gate review found on 1234567890.5 and 45678901234.5. With that fixed, it matches all 75 with no width change. Settled by b2. b2 compares text, not pixels, so fonts on the runner do not matter.
- code: the formula bar already parses as Calc does, so its path passes on main, and its own display of a cell as typed stays as it is (out of scope: a-i10's rules). Settled by b1's bar column.
- code: a CSV field 'abc that is now the text abc is still saved back as 'abc when untouched once a-v1-csv-text lands (it writes untouched fields as written). Settled by a-v1-csv-text's checks.

Replan (gate review 1 of 2): b2 now pins Calc's rounding at the cut and has held-out cases, as the reviewer asked. The design says plainly that 50% shows as 0.5, not 50% as the outcome's Expected has it, because the product has no number formats.
Learned from RECORD.md and the overlapping pages: a-i10 kept the bar's typed-input rules local rather than importing grid.js ('the checks pin the same behavior'), and the review found exactly that drift (S23). So b1 drives all three paths through the shipped page and compares what each stores. a-i10's reviewer noted 50% committing as 0.5 in the bar only. S25 was tagged conflict-with-spec? because the CLI and the grid differ. Running Calc shows the grid's 1E+15 matches Calc at standard width, and the real mismatches are elsewhere, which is why expected values come from Calc's own drawing and not from the review's text. a-i6's number-to-text defect (src/values: &, CONCATENATE, LEN) is a-v1-number-text's and is not touched. Overlaps: a-v1-big-sheets, a-v1-cell-edit and a-v1-grid-keys also change grid.js (mount, editing), and a-v1-csv-text changes io.js (saveCSV). This plan touches only parseInput and display/formatNumber.

Check files in full, as the HITL's delegate asked (b1 types into a grid cell, into the formula bar and opens a CSV, all on the shipped page; b2 reads the text the grid draws):

=== tests/e2e/ui/checks/a_v1_ed_b1.mjs (in full, as on the plan branch) ===
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


=== tests/e2e/ui/checks/a_v1_ed_page.mjs (in full, as on the plan branch) ===
// Shared by the a-v1-entry-display checks: the app page in headless Chrome (a_r2_cdp.mjs), real mouse and keys,
// and what Save JSON writes. Node standard library only. Calc's answers: a_v1_ed_calc.json.
import { mkdtempSync, writeFileSync, readFileSync, existsSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { findBrowser, serve, launch, sleep } from "./a_r2_cdp.mjs";

export const CALC = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "a_v1_ed_calc.json"), "utf8"));
export const fail = (m) => { console.log("FAIL " + m); process.exit(1); };
const VK = { Enter: 13, "'": 222, "%": 53, "-": 189, Escape: 27, F2: 113, End: 35, Home: 36, Backspace: 8, ArrowDown: 40, ArrowUp: 38 };

// Opens web/io/index.html as web/io/serve.py serves it and picks `name` holding `text` in #open; `ready` is a
// [ref, shown] pair the grid shows once the file is open.
export async function openPage(name, text, ready) {
  const browser = findBrowser();
  if (!browser) fail("no browser: set CHROME or put google-chrome or chromium on PATH");
  const dir = mkdtempSync(join(tmpdir(), "a-v1-ed-"));
  const file = join(dir, name), saved = join(dir, "saved");
  writeFileSync(file, text);
  const server = await serve();
  const b = await launch(browser);
  const errors = [];
  b.on("Runtime.exceptionThrown", (p) => errors.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text));
  const done = (code) => {
    if (code === 0 && errors.length) { console.log("FAIL the page threw: " + errors.join(" | ")); code = 1; }
    b.close(); server.close(); process.exit(code);
  };
  await b.send("Runtime.enable");
  await b.send("Page.enable");
  await b.send("Browser.setDownloadBehavior", { behavior: "allow", downloadPath: saved });
  const js = async (expr) => (await b.send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })).result.value;
  const until = async (what, expr, want, tries = 100) => {
    let got;
    for (let t = 0; t < tries; t++) { got = await js(expr); if (got === want) return; await sleep(100); }
    fail(`${what}: wanted ${JSON.stringify(want)}, the page shows ${JSON.stringify(got)}`);
  };
  await b.send("Page.navigate", { url: server.url + "/io/index.html" });
  await until("the page loads with its grid", `!!document.querySelector('#grid td[data-ref="A1"]')`, true);
  const doc = await b.send("DOM.getDocument");
  const input = await b.send("DOM.querySelector", { nodeId: doc.root.nodeId, selector: "#open" });
  if (!input.nodeId) fail("the page has no #open file input");
  await b.send("DOM.setFileInputFiles", { nodeId: input.nodeId, files: [file] });
  await until(`after Open, ${ready[0]} shows ${ready[1]}`, cellText(ready[0]), ready[1]);
  // Some desktop Chromium builds open an extension tab at start that hides the page; keep the page in front.
  const front = async () => { if ((await js("document.visibilityState")) !== "visible") await b.send("Page.bringToFront"); };
  await sleep(1500);
  await front();

  // A real click (clickCount 1) or double-click (1 then 2, as a mouse sends it) at the cell's centre.
  const click = async (ref, count = 1) => {
    await front();
    const r = await js(`(() => { const e = document.querySelector('#grid td[data-ref="${ref}"]'); if (!e) return null;
      const r = e.getBoundingClientRect(); return {x: r.x + r.width / 2, y: r.y + r.height / 2}; })()`);
    if (!r) fail(`the grid has no cell ${ref}`);
    for (let n = 1; n <= count; n++)
      for (const type of ["mousePressed", "mouseReleased"]) await b.send("Input.dispatchMouseEvent", { type, ...r, button: "left", clickCount: n });
    await sleep(50);
  };
  const key = async (k) => {
    await front();
    for (const type of ["keyDown", "keyUp"]) await b.send("Input.dispatchKeyEvent", { type, key: k, code: k, windowsVirtualKeyCode: VK[k] });
    await sleep(30);
  };
  const type = async (text) => { await front(); await b.send("Input.insertText", { text }); await sleep(30); };
  // Save JSON (#save-json) and read the downloaded book.json's Sheet1.
  const savedSheet = async () => {
    rmSync(saved, { recursive: true, force: true });
    await js(`document.getElementById("save-json").click()`);
    const out = join(saved, name.replace(/\.[^.]*$/, "") + ".json");
    for (let t = 0; t < 100 && !existsSync(out); t++) await sleep(100);
    await sleep(200);
    if (!existsSync(out)) fail("Save JSON downloaded nothing");
    return JSON.parse(readFileSync(out, "utf8")).sheets?.Sheet1;
  };
  // Types `text` into the formula bar for the selected cell and presses Enter.
  const inBar = async (text) => {
    await front();
    const r = await js(`(() => { const e = document.querySelector('#formula-bar input[aria-label="Formula"]'); if (!e) return null;
      const r = e.getBoundingClientRect(); return {x: r.x + r.width / 2, y: r.y + r.height / 2}; })()`);
    if (!r) fail("the page has no formula bar input");
    for (const t of ["mousePressed", "mouseReleased"]) await b.send("Input.dispatchMouseEvent", { type: t, ...r, button: "left", clickCount: 1 });
    await b.send("Input.dispatchKeyEvent", { type: "rawKeyDown", commands: ["selectAll"], key: "a", code: "KeyA", modifiers: 2 });
    await b.send("Input.dispatchKeyEvent", { type: "keyUp", key: "a", code: "KeyA", modifiers: 2 });
    await type(text);
    await key("Enter");
  };
  return { b, js, until, done, click, key, type, savedSheet, editor, inBar };
}

export const cellText = (ref) => `document.querySelector('#grid td[data-ref="${ref}"]')?.textContent.trim() ?? null`;
export const selectedRef = `document.querySelector('#grid td.selected')?.dataset.ref ?? null`;
// The open in-cell editor's text, or null when no editor is open inside the grid.
const editor = `document.querySelector('#grid td input, #grid td textarea, #grid td [contenteditable=true]')?.value ?? null`;
export { editor, sleep };


=== tests/e2e/ui/checks/a_v1_ed_b2.mjs (in full, as on the plan branch) ===
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

Replan 2 (gate review 2, and the delegate's answer to it): which text each caller uses. The gate found that the grid's display() also feeds inputText (the in-cell editor's start text, and the text index.html re-parses on every grid commit) and Save CSV. WI 2's column-fitted text would then silently cut stored numbers: 123456789012 would be kept as 123457000000. So the grid gets two texts:
- display(v): the column-fitted General text (WI 2). Only the drawn td uses it.
- fullText(v): a number with every digit it needs to read back as the same double (123456789012, 3.141592653589793, E notation as 1E+21). inputText uses it, so a grid commit and F2+Enter keep a value exactly.
- inputText(text): text that would read back as something else gets Calc's leading apostrophe back ('123, 'TRUE, as Calc's input line shows them), so '123 typed in the grid stays the text "123" (WI 1).
- Save CSV (io.js csvField): a number the user typed (a constant in the workbook as typed) is written with fullText. A formula's result is written as Calc's General text, up to 15 digits, not fitted (0.1+0.2 stays 0.3, as a-i11's a11_b2_csv.sh pins). toCSV gets the typed workbook as an optional third argument, and saveCSV passes it.
WI 2 now depends on WI 1 (both change web/grid/grid.js) and carries the new check a_v1_ed_b1_keep.sh, which covers b1.

More beliefs (replan 2):
- ran: Calc keeps typed 123456789012 and 3.141592653589793 exactly, and keeps '123 and 'TRUE as the texts "123" and "TRUE", with input-line text '123 and 'TRUE (a_v1_ed_keep_probe.py, a_v1_ed_keep.json). Settled by a_v1_ed_b1_keep.sh.
- ran: on main (36e13b4) the keep check fails as the gate said: 3.141592653589793 is kept as 3.14159265358979, '123 as the text "'123", and Save CSV writes 3.14159265358979. With inputText fed a column-fitted text (simulated), it also fails on 123456789012 (kept as 123457000000), so it catches the regression the gate found. The evidence prototype-keep.diff (about 25 lines in grid.js and io.js) passes it, a_v1_ed_b1_entry.sh, a11_b2_csv.sh, the a9/a11 checks, a-r2's walk-through and a-r0's browser check; ./test.sh is OK.
- human: Calc's input line itself shows only 15 digits (3.14159265358979). The plan follows the delegate's ruling instead ('F2 then Enter leaves them unchanged', 'Save CSV writes them in full'), because a cut there would change the stored value. Settled by that answer.
- ran: writing every number with fullText would break a-i11's landed check (0.30000000000000004 instead of 0.3), which is why formula results keep the 15-digit General text. Settled by a11_b2_csv.sh staying green.

Files the checks load, in full (plan commit 4ba6dd7 = 920df5b plus the replan 2 files below):

tests/e2e/ui/checks/a_v1_ed_calc.json, in full (one line in the file; a_v1_ed_page.mjs loads it as CALC: "entries" are the four typed entries for b1 with what Calc stores and shows, "numbers" the 75 values for b2 with the text Calc's General format shows at the standard column width):
```json
{"source": "LibreOffice Calc 26.8.1.1 headless, by a_v1_ed_probe.py (shown: PDF export of General cells in the standard column width, read by pdftotext)", "entry": {"typed": {"50%": {"number": 0.5}, "1e3": {"number": 1000.0}, "-2.5": {"number": -2.5}, "'abc": {"text": "abc"}}, "csv": {"50%": {"number": 0.5}, "1e3": {"number": 1000.0}, "-2.5": {"number": -2.5}, "'abc": {"text": "'abc"}}}, "shown": [["1000000000000001", "1E+15"], ["1234567890123456", "1.23457E+15"], ["1e-07", "0.0000001"], ["0.3333333333333333", "0.333333333"], ["0.6666666666666666", "0.666666667"], ["1e+20", "1E+020"], ["-1234567.891", "-1234567.891"], ["123456.789", "123456.789"], ["0.000123456", "0.000123456"], ["99999999999", "99999999999"], ["12345678901", "12345678901"], ["123456789012", "1.23457E+11"], ["0.30000000000000004", "0.3"], ["123456789", "123456789"], ["-1.234e-06", "-0.000001234"], ["1e-20", "1E-20"], ["3.141592653589793", "3.141592654"], ["1000000000000000.0", "1E+15"], ["1e+100", "1E+100"], ["-1e-100", "-1E-100"], ["0.5", "0.5"], ["1000", "1000"], ["-2.5", "-2.5"], ["1234.5678", "1234.5678"], ["98765.4321", "98765.4321"], ["0.1", "0.1"], ["1e-05", "0.00001"], ["1.234567e-05", "1.23457E-05"], ["10000000000.0", "10000000000"], ["123456789.123", "123456789.1"], ["-98765432.1", "-98765432.1"], ["1.5e-08", "0.000000015"], ["7", "7"], ["-0.25", "-0.25"], ["1234567890.5", "1234567891"], ["45678901234.5", "45678901235"], ["-1234567890.5", "-1234567891"], ["9876543210.5", "9876543211"], ["2345678901.5", "2345678902"], ["12345678901.5", "12345678902"], ["99999999999.5", "1E+11"], ["9999999999.5", "10000000000"], ["0.1234567895", "0.12345679"], ["1.0000000005", "1.000000001"], ["12.345678905", "12.34567891"], ["123.45678905", "123.4567891"], ["3.3333333335", "3.333333334"], ["-0.6666666665", "-0.666666667"], ["0.9999999995", "1"], ["1234565000000000", "1.23457E+15"], ["9.999995e+20", "1E+21"], ["1.234565e-10", "1.23457E-10"], ["-2.345675e+30", "-2.3457E+30"], ["5000005000000000.0", "5.00001E+15"], ["123456.78905", "123456.7891"], ["0.000999", "0.000999"], ["123456.5", "123456.5"], ["12345.678901", "12345.6789"], ["3.5e-05", "0.000035"], ["6.02214076e+23", "6.02214E+23"], ["1.602176634e-19", "1.60218E-19"], ["299792458", "299792458"], ["0.012345678912", "0.012345679"], ["98765432109", "98765432109"], ["4.5e-07", "0.00000045"], ["0.2857142857142857", "0.285714286"], ["3.142857142857143", "3.142857143"], ["100000000000000.0", "1E+14"], ["100000000000000.5", "1E+14"], ["314159.265358979", "314159.2654"], ["-1.23456789e-07", "-1.23457E-07"], ["1.2345e-05", "0.000012345"], ["77777777777.7", "77777777778"], ["-9999999999.9", "-1E+10"], ["9.9999e-07", "9.9999E-07"]]}
```
tests/e2e/ui/checks/a_v1_ed_probe.py, in full (it wrote a_v1_ed_calc.json from LibreOffice Calc; the checks never run it):
```python
"""Where a_v1_ed_calc.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

entry: each of TYPED entered into a cell as a user types it (XCell.setFormula on text = Calc's input rule),
and the same fields read by Calc's default CSV import: type and value. shown: each number of NUMBERS (incl.
halves at the cut and held-out values) in a
General-format cell of the standard column width (Calc's default, 2.258 cm), as Calc draws it: the sheet is
exported to PDF and read back with pdftotext -layout. Run: python3 a_v1_ed_probe.py /tmp/x (soffice, uno, poppler).
"""
import json, os, subprocess, sys, tempfile, time
import uno
from com.sun.star.beans import PropertyValue

TYPED = ["50%", "1e3", "-2.5", "'abc"]
NUMBERS = [1000000000000001, 1234567890123456, 1e-07, 1 / 3, 2 / 3, 1e20, -1234567.891, 123456.789, 0.000123456,
           99999999999, 12345678901, 123456789012, 0.30000000000000004, 123456789, -0.000001234, 1e-20, 3.141592653589793,
           1e15, 1e100, -1e-100, 0.5, 1000, -2.5, 1234.5678, 98765.4321, 0.1, 1e-05, 0.00001234567, 1e10, 123456789.123,
           -98765432.1, 1.5e-08, 7, -0.25,
           # halves where the column cuts digits (Calc rounds half away from zero), at integer, decimal and E cuts
           1234567890.5, 45678901234.5, -1234567890.5, 9876543210.5, 2345678901.5, 12345678901.5, 99999999999.5,
           9999999999.5, 0.1234567895, 1.0000000005, 12.345678905, 123.45678905, 3.3333333335, -0.6666666665,
           0.9999999995, 1234565000000000, 9.999995e20, 1.234565e-10, -2.345675e30, 5.000005e15, 123456.78905,
           # held out: not used to tune any model of the rule
           0.000999, 123456.5, 12345.678901, 3.5e-05, 6.02214076e23, 1.602176634e-19, 299792458, 0.012345678912,
           98765432109, 4.5e-07, 2 / 7, 22 / 7, 1e14, 100000000000000.5, 314159.265358979, -0.000000123456789,
           0.000012345, 77777777777.7, -9999999999.9, 0.00000099999]
d = sys.argv[1] if len(sys.argv) > 1 else tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/prof",
                      "--accept=socket,host=127.0.0.1,port=2307;urp;"])
ctx = uno.getComponentContext()
res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
for _ in range(60):
    try:
        c = res.resolve("uno:socket,host=127.0.0.1,port=2307;urp;StarOffice.ComponentContext"); break
    except Exception:
        time.sleep(0.5)
desk = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c)
def pv(n, v):
    x = PropertyValue(); x.Name = n; x.Value = v; return x
def kind(x):
    return {"text": x.getString()} if x.getType().value == "TEXT" else {"number": x.getValue()}
doc = desk.loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
sh = doc.Sheets.getByIndex(0)
for i, t in enumerate(TYPED): sh.getCellByPosition(0, i).setFormula(t)
out = {"entry": {"typed": {t: kind(sh.getCellByPosition(0, i)) for i, t in enumerate(TYPED)}}}
for i, x in enumerate(NUMBERS):
    sh.getCellByPosition(1, i).setValue(float(x)); sh.getCellByPosition(2, i).setString("#%d#" % i)
doc.calculateAll()
doc.storeToURL(uno.systemPathToFileUrl(os.path.join(d, "shown.pdf")), (pv("FilterName", "calc_pdf_Export"),))
doc.close(True)
text = subprocess.run(["pdftotext", "-layout", os.path.join(d, "shown.pdf"), "-"], capture_output=True, text=True).stdout
shown = {}
for line in text.splitlines():
    parts = line.split()
    if len(parts) >= 2 and parts[-1].startswith("#") and parts[-1].endswith("#"): shown[int(parts[-1][1:-1])] = parts[-2]
out["shown"] = [[repr(x), shown.get(i)] for i, x in enumerate(NUMBERS)]
csv = os.path.join(d, "entry.csv")
open(csv, "w").write(",".join(TYPED) + "\n")
doc = desk.loadComponentFromURL(uno.systemPathToFileUrl(csv), "_blank", 0, (pv("Hidden", True), pv("FilterName", "Text - txt - csv (StarCalc)"), pv("FilterOptions", "44,34,76,1")))
sh = doc.Sheets.getByIndex(0)
out["entry"]["csv"] = {t: kind(sh.getCellByPosition(i, 0)) for i, t in enumerate(TYPED)}
print(json.dumps(out))
doc.close(True)
try: desk.terminate()
except Exception: pass
p.wait(timeout=30)
```

Replan 2 files, in full:
tests/e2e/ui/checks/a_v1_ed_b1_keep.sh:
```sh
#!/bin/sh
# b1, values kept (plan a-v1-entry-display, after gate review 2): the grid draws a number to fit its column, but what
# the user typed is kept. In headless Chrome on the shipped page (web/io/serve.py, /io/index.html), with real keys:
# type 123456789012, 3.141592653589793, '123 and 'TRUE into A1:A4. Save JSON holds Calc's values exactly (the two
# numbers to the last digit, the texts "123" and "TRUE"); F2 opens each with text that reads back the same ('123 and
# 'TRUE as Calc's input line shows them), and Enter changes nothing; Save CSV writes both numbers in full.
# Values: a_v1_ed_keep.json, from LibreOffice Calc (a_v1_ed_keep_probe.py). Steps: a_v1_ed_b1_keep.mjs.
set -eu
cd "$(dirname "$0")/../../../.."
command -v node >/dev/null || { echo "FAIL: node is not installed"; exit 1; }
export PYTHONDONTWRITEBYTECODE=1
exec node tests/e2e/ui/checks/a_v1_ed_b1_keep.mjs
```
tests/e2e/ui/checks/a_v1_ed_b1_keep.mjs (uses openPage, sleep and editor from a_v1_ed_page.mjs, pasted earlier):
```js
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
```
tests/e2e/ui/checks/a_v1_ed_keep.json:
```json
{"source": "LibreOffice Calc 26.8.1.1 headless, by a_v1_ed_keep_probe.py", "typed": {"123456789012": {"number": 123456789012.0, "input_line": "123456789012"}, "3.141592653589793": {"number": 3.141592653589793, "input_line": "3.14159265358979"}, "'123": {"text": "123", "input_line": "'123"}, "'TRUE": {"text": "TRUE", "input_line": "'TRUE"}}}
```
tests/e2e/ui/checks/a_v1_ed_keep_probe.py:
```python
"""Where a_v1_ed_keep.json comes from: LibreOffice Calc itself, headless, over UNO (not run by the checks).

Each entry is typed into a cell of a new Calc document (setFormula, as the input line takes it); Calc's stored
value and its input-line text (getFormula) are written to a_v1_ed_keep.json. Run: python3 a_v1_ed_keep_probe.py
"""
import json, os, subprocess, tempfile, time, uno
d = tempfile.mkdtemp()
p = subprocess.Popen(["soffice", "--headless", "--invisible", "--norestore", "-env:UserInstallation=file://" + d + "/p",
                      "--accept=socket,host=127.0.0.1,port=2315;urp;"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    ctx = uno.getComponentContext()
    res = ctx.ServiceManager.createInstanceWithContext("com.sun.star.bridge.UnoUrlResolver", ctx)
    for _ in range(60):
        try: c = res.resolve("uno:socket,host=127.0.0.1,port=2315;urp;StarOffice.ComponentContext"); break
        except Exception: time.sleep(0.5)
    doc = c.ServiceManager.createInstanceWithContext("com.sun.star.frame.Desktop", c).loadComponentFromURL("private:factory/scalc", "_blank", 0, ())
    sh = doc.Sheets.getByIndex(0); out = {}
    for i, t in enumerate(["123456789012", "3.141592653589793", "'123", "'TRUE"]):
        x = sh.getCellByPosition(0, i); x.setFormula(t)
        out[t] = {"number": x.getValue()} if x.getType().value == "VALUE" else {"text": x.getString()}
        out[t]["input_line"] = x.getFormula()
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "a_v1_ed_keep.json"), "w") as f:
        f.write(json.dumps({"source": "LibreOffice Calc 26.8.1.1 headless, by a_v1_ed_keep_probe.py", "typed": out}) + "\n")
    doc.close(True)
finally:
    p.kill()
```

- **Reuses:** The formula bar's parseInput rule (apostrophe, percent, numbers, booleans), the grid's parseInput/display/formatNumber entry points and their callers (io.js parseCSV, toCSV), and a_r2_cdp.mjs for the browser checks.
- **Removes:** The grid's fixed 15-digit / 1E-05 display rule, and the grid's and CSV's treatment of 50% and 'abc as plain text.
- **Rejected:** Showing Calc's full General text (getString) in the grid: Calc itself shortens numbers to the column (=10^15+1 shows 1E+15), and the bullet says 'for a standard column width'. Measuring rendered text width in the browser (canvas measureText): it depends on the runner's fonts, so tests would differ between machines, whereas a fixed width table is deterministic and matches Calc's texts. Auto-applying a percent format to 50% (Calc shows 50%, the outcome's Expected): the product has no number formats ('number formats chosen by the user' are out of scope), and the bullets ask for the value 0.5. So 50% will display as 0.5; a percent display needs its own intent. Making the bar import grid.js: a-i10 rejected that coupling.

## 4. Work items

### `wi-a-v1-entry-display-1`: One entry rule for grid, bar and CSV

The grid's parseInput, which parseCSV also uses, follows the formula bar's rule: 50% is 0.5, a leading apostrophe makes text and is dropped, 1e3 is 1000. So typing in a cell, in the bar or opening a CSV stores the same values, as Calc enters them. A text that would read back as a number or TRUE/FALSE comes back with its apostrophe in the editor ('123), so it stays text.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ed-b1` | b1 | `tests/e2e/ui/checks/a_v1_ed_b1_entry.sh` | red | — |

### `wi-a-v1-entry-display-2`: Grid numbers in Calc's General format

The grid's number display fits each number to a standard column the way Calc's General format does (fewer decimals or a shorter E-mantissa, decimal when exact), so 1E-7 shows 0.0000001, 1234567890123456 shows 1.23457E+15 and halves round away from zero, as LibreOffice draws them. Only the drawn cell uses that fitted text: the editor, the page's commits and typed numbers in Save CSV use the full text, so no typed digit is lost.

Status: accepted · depends on `wi-a-v1-entry-display-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ed-b2` | b2 | `tests/e2e/ui/checks/a_v1_ed_b2_display.sh` | red | — |
| `ac-ed-keep` | b1 | `tests/e2e/ui/checks/a_v1_ed_b1_keep.sh` | red | — |

### `wi-a-v1-entry-display-3`: Product tests for entry and display

Adds tests/e2e/ui/test_entry_display.py, run by ./test.sh in headless Chrome, covering the three entry paths and Calc's General display, so the product keeps this behaviour.

Status: accepted · depends on `wi-a-v1-entry-display-1`, `wi-a-v1-entry-display-2`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ed-suite` | b1, b2 | `tests/e2e/ui/checks/a_v1_ed_suite.sh` | red | — |
| `ac-ed-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), can an ordinary user type values like 50%, 1e3, -2.5 and 'abc into cells or the formula bar, or open a CSV containing them, and get the same, sensible values each way (formulas over 50% work), and do the numbers they see in the grid (large, small, long decimals) read like a spreadsheet shows them? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | 50%, 1e3, -2.5 and 'abc typed in the grid, typed in the formula bar, or read from a CSV become the same values (0.5, 1000, -2.5, text abc), as Calc enters them | no landed check |
| not yet | b2 | the grid shows numbers as Calc's General format does for a standard column width, with expected values taken from running LibreOffice | no landed check |

## 5. Out of scope and risks

- **Out of scope:** number formats chosen by the user
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/formula_bar/**`, `exp-a:web/io/io.js`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/formula_bar/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-entry-display-1` | — |
| Reviewed `wi-a-v1-entry-display-1` | — |
| Implemented `wi-a-v1-entry-display-2` | — |
| Reviewed `wi-a-v1-entry-display-2` | — |
| Implemented `wi-a-v1-entry-display-3` | — |
| Reviewed `wi-a-v1-entry-display-3` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 5 h 47 min so far
- Loops: 6 (D1 spec 2, D2 plan 4)
- Waste: 2 h 03 min
- Size: nothing landed yet
