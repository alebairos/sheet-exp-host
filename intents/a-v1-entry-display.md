# Intent `a-v1-entry-display`

## 1. Outcome

> The same input gives different results depending on where I type it, and the grid shows numbers unlike Calc. Observed: 50% typed in the grid is stored as text (=A1*2 gives #VALUE!), in the formula bar it is 0.5, in a CSV it is text; =10^15+1 shows as 1E+15 in the grid (the CLI gives 1000000000000001), 1E-7 shows 1E-07 (G12, G16; prior S23, S25). Expected, as in Calc: one entry rule for grid, bar and CSV (50% is the number 0.5, shown 50%), and numbers shown as Calc's General format shows them. (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: certified · 3 work items · 2 bullets

## 2. What you will see

Typing behaves the same everywhere. 50% typed in a grid cell, in the formula bar or found in a CSV is the number 0.5 (so =A1*2 is 1, not #VALUE!), 1e3 is 1000, -2.5 is -2.5, and 'abc is the text abc, as when you type them in Calc. Note: the cell then shows 0.5, not 50% as the outcome's Expected says; Calc shows 50% because it also applies a percent format on entry, and the product has no number formats (out of scope here). The grid draws numbers the way Calc's General format draws them in a normal-width column: 1234567890123456 shows 1.23457E+15, 0.0000001 shows 0.0000001 (not 1E-07), 1/3 shows 0.333333333, 123456789.123 shows 123456789.1, and 1234567890.5 shows 1234567891 (Calc rounds halves away from zero). Calc's own drawing of the 75 numbers is in calc-shown.pdf.

- [a-v1-entry-display/README.md](https://github.com/alebairos/sheet-exp-host/blob/afdf48c5b2a68f6d15650388101b1ada9a478c02/a-v1-entry-display/README.md)
- [a-v1-entry-display/calc-shown.pdf](https://github.com/alebairos/sheet-exp-host/blob/afdf48c5b2a68f6d15650388101b1ada9a478c02/a-v1-entry-display/calc-shown.pdf)
- [a-v1-entry-display/today-checks.txt](https://github.com/alebairos/sheet-exp-host/blob/afdf48c5b2a68f6d15650388101b1ada9a478c02/a-v1-entry-display/today-checks.txt)
- [a-v1-entry-display/general_model.py](https://github.com/alebairos/sheet-exp-host/blob/afdf48c5b2a68f6d15650388101b1ada9a478c02/a-v1-entry-display/general_model.py)

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

- **Reuses:** The formula bar's parseInput rule (apostrophe, percent, numbers, booleans), the grid's parseInput/display/formatNumber entry points and their callers (io.js parseCSV, toCSV), and a_r2_cdp.mjs for the browser checks.
- **Removes:** The grid's fixed 15-digit / 1E-05 display rule, and the grid's and CSV's treatment of 50% and 'abc as plain text.
- **Rejected:** Showing Calc's full General text (getString) in the grid: Calc itself shortens numbers to the column (=10^15+1 shows 1E+15), and the bullet says 'for a standard column width'. Measuring rendered text width in the browser (canvas measureText): it depends on the runner's fonts, so tests would differ between machines, whereas a fixed width table is deterministic and matches Calc's texts. Auto-applying a percent format to 50% (Calc shows 50%, the outcome's Expected): the product has no number formats ('number formats chosen by the user' are out of scope), and the bullets ask for the value 0.5. So 50% will display as 0.5; a percent display needs its own intent. Making the bar import grid.js: a-i10 rejected that coupling.

## 4. Work items

### `wi-a-v1-entry-display-1`: One entry rule for grid, bar and CSV

The grid's parseInput, which parseCSV also uses, follows the formula bar's rule: 50% is 0.5, a leading apostrophe makes text and is dropped, 1e3 is 1000. So typing in a cell, in the bar or opening a CSV stores the same values, as Calc enters them.

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ed-b1` | b1 | `tests/e2e/ui/checks/a_v1_ed_b1_entry.sh` | red | — |

### `wi-a-v1-entry-display-2`: Grid numbers in Calc's General format

The grid's number display fits each number to a standard column the way Calc's General format does (fewer decimals or a shorter E-mantissa, decimal when exact), so 1E-7 shows 0.0000001, 1234567890123456 shows 1.23457E+15 and halves round away from zero, as LibreOffice draws them.

Status: planned

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-ed-b2` | b2 | `tests/e2e/ui/checks/a_v1_ed_b2_display.sh` | red | — |

### `wi-a-v1-entry-display-3`: Product tests for entry and display

Adds tests/e2e/ui/test_entry_display.py, run by ./test.sh in headless Chrome, covering the three entry paths and Calc's General display, so the product keeps this behaviour.

Status: planned · depends on `wi-a-v1-entry-display-1`, `wi-a-v1-entry-display-2`

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

**SpecAccept:a-v1-entry-display**: A decision: show your human its options

- Accept the spec: claims freeze, it can be admitted: `cooknship decide --answer SpecAccept:a-v1-entry-display --option accept`
- Send the plan back with a reason: `cooknship decide --answer SpecAccept:a-v1-entry-display --option reject --text "<reason>"`
- Shelve it; when another intent takes its place, the reason is replaced:<that intent's id>, and what waits on this one waits for it instead: `cooknship decide --answer SpecAccept:a-v1-entry-display --option shelve --text "<reason>"`

## 8. Metrics

- Lead time: 3 h 10 min so far
- Loops: 3 (D1 spec 1, D2 plan 2)
- Waste: 11 min
- Size: nothing landed yet
