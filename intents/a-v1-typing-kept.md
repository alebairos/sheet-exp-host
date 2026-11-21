# Intent `a-v1-typing-kept`

## 1. Outcome

> In the browser, keystrokes typed while the workbook recomputes are lost. Observed: on a workbook that takes ~2.7 s to compute, type 1 and Enter, then at once type a long formula at 120 ms per key: when the recompute returns the redraw removes the open editor, the formula is lost or a partial one committed, and focus goes to BODY. Expected: every keystroke typed lands in the cell being edited, whatever the engine is doing (G4; prior S14, "data-loss"). (review: https://github.com/alebairos/sheet-exp-host/blob/567e74b/a-v1-review/README.md)

Kind: Defect · State: accepted · 2 work items · 2 bullets

## 2. What you will see

Typing is never lost while the workbook recomputes. Type a value, press Enter and start typing in the next cell straight away: when the recompute comes back, the cell you are typing in stays open with everything you typed and the cursor where you left it, the keyboard stays in the grid, and nothing is saved until you press Enter (Escape still cancels). Nothing else about editing changes.

- [a-v1-typing-kept/README.md](https://github.com/alebairos/sheet-exp-host/blob/93aef53ff1b637ef2da6ca9e446140f0cd9715d1/a-v1-typing-kept/README.md)
- [a-v1-typing-kept/today.txt](https://github.com/alebairos/sheet-exp-host/blob/93aef53ff1b637ef2da6ca9e446140f0cd9715d1/a-v1-typing-kept/today.txt)
- [a-v1-typing-kept/prototype.diff](https://github.com/alebairos/sheet-exp-host/blob/93aef53ff1b637ef2da6ca9e446140f0cd9715d1/a-v1-typing-kept/prototype.diff)

## 3. Approach

Cause, as read in web/grid/grid.js and web/io/index.html and run on main (2070717). After Enter the page sends the workbook to POST /compute. When the answer comes back it calls show(), which calls grid.setState(). setState redraws the table (draw sets editing = null and replaces innerHTML), which removes any open cell editor. Focus falls to BODY, so the next keys go nowhere: the formula typed so far is lost, and with the old blur commit a part of it could be committed (S14).
Fix (WI 1, web/grid/grid.js, about 20 lines, as in the evidence prototype). setState() notes an open editor: its input, cell, caret (selectionStart/End/direction) and whether it had focus. It redraws as now, then puts the same input back into the cell (scrolling to it if needed), restores the caret and focus, and keeps it as the open edit. Its listeners stay as they were, so Enter commits, Escape cancels and nothing commits in between. The page (index.html) needs no change, because it already redraws at grid.state.selected. WI 2 adds tests/e2e/ui/typing_kept.mjs and tests/e2e/ui/test_typing_kept.py, so ./test.sh keeps it (skipped only without node or a browser, as the walk-through is).

Beliefs:
- ran: on main both checks fail. After A2's recompute comes back, A3's editor is null and focus is on BODY (evidence today.txt). Settled by a_v1_tk_b1_kept.sh and a_v1_tk_b2_open.sh.
- ran: on the prototype, b1 (4 scenarios), b2 (2 scenarios) and the suite check pass; ./test.sh runs 77 tests, OK; a9, a10, a11, a-r0, a-r2 and big-sheets' checks still pass. Settled by the land test.
- ran: holding POST /compute with the DevTools Fetch domain reproduces the review's race on every run. The live scenario (2,000 rows, about 1.9 s to compute here, nothing held) shows the same without any hold: it types until C1 =A2*10 shows the recompute came back. Settled by b1.
- ran: the values the checks expect after Enter (A3 = 8 and 5, C1 = 50) come from LibreOffice Calc 26.8.1.1 (a_v1_tk_probe.py, a_v1_tk_calc.json), for every formula the checks type. Settled by b1, b2.
- code: moving a focused input out of a removed table can fire blur. draw() clears `editing` before it replaces the table, so the old blur handler commits nothing. Settled by b1's 'no recompute before Enter'.
- memory: on this desktop, policy extension tabs can hide the headless page. The helper brings it to the front once it has loaded. A land runner has no such tabs.
- human: the formula bar losing typed text on a redraw is a-v1-grid-keys' b3, not this intent's: this outcome is the cell editor.

Learned from RECORD.md and the overlapping pages: S14 (keys lost or a partial formula committed, intermittent) is this race. It was intermittent in the review because it needs a recompute to come back mid-typing, so the checks force it instead of hoping for it. a-i11's attempt 1 stacked listeners on every redraw, so the fix reuses the same input and adds no listener. Overlaps in web/grid/grid.js: a-v1-grid-keys (mousedown selection, Tab, the bar's commit on redraw), a-v1-cell-edit (what the in-cell editor starts with), a-v1-big-sheets (scrolling, already on main) and a-v1-keep-work. None of them keeps an open editor across setState, and this plan changes only setState and adds reopen(). The usefulness judge is on the shipped page, typing at a normal speed on a slow workbook.

tests/e2e/ui/checks/a_v1_tk_b1.mjs, in full:
```js
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
```
tests/e2e/ui/checks/a_v1_tk_b2.mjs, in full:
```js
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
```
tests/e2e/ui/checks/a_v1_tk_page.mjs, in full (both import it; a_r2_cdp.mjs is a-r2's landed browser helper):
```js
// Shared by the a-v1-typing-kept checks: the app page (web/io/serve.py, /io/index.html) in headless Chrome
// (a_r2_cdp.mjs), real key presses, and the page's POST /compute held by the DevTools Fetch domain so that a
// recompute returns exactly while the user is typing (a slow engine, made deterministic). Node standard library.
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { findBrowser, serve, launch, sleep } from "./a_r2_cdp.mjs";

export const fail = (m) => { console.log("FAIL " + m); process.exit(1); };
export { sleep };

// Opens the page with `book` (workbook JSON) through #open; returns the page and its helpers.
export async function openBook(book) {
  const browser = findBrowser();
  if (!browser) fail("no browser: set CHROME or put google-chrome or chromium on PATH");
  const dir = mkdtempSync(join(tmpdir(), "a-v1-tk-"));
  const file = join(dir, "book.json");
  writeFileSync(file, JSON.stringify(book));
  const server = await serve();
  const b = await launch(browser);
  const errors = [], held = [];
  let holding = false, computes = 0;
  b.on("Runtime.exceptionThrown", (p) => errors.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text));
  // Every POST /compute is counted; while holding, it waits until release() lets it through.
  b.on("Fetch.requestPaused", (p) => { computes++; if (holding) held.push(p.requestId); else b.send("Fetch.continueRequest", { requestId: p.requestId }); });
  await b.send("Runtime.enable");
  await b.send("Page.enable");
  await b.send("Fetch.enable", { patterns: [{ urlPattern: "*/compute*", requestStage: "Request" }] });
  const js = async (expr) => (await b.send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })).result.value;
  const until = async (what, expr, want, tries = 100) => {
    let got;
    for (let t = 0; t < tries; t++) { got = await js(expr); if (JSON.stringify(got) === JSON.stringify(want)) return; await sleep(100); }
    fail(`${what}: wanted ${JSON.stringify(want)}, the page shows ${JSON.stringify(got)}`);
  };
  const done = (code) => {
    if (code === 0 && errors.length) { console.log("FAIL the page threw: " + errors.join(" | ")); code = 1; }
    b.close(); server.close(); rmSync(dir, { recursive: true, force: true }); process.exit(code);
  };
  await b.send("Page.navigate", { url: server.url + "/io/index.html" });
  await until("the page loads with its grid", `!!document.querySelector('#grid td[data-ref="A1"]')`, true);
  if ((await js("document.visibilityState")) !== "visible") await b.send("Page.bringToFront");
  const doc = await b.send("DOM.getDocument");
  const input = await b.send("DOM.querySelector", { nodeId: doc.root.nodeId, selector: "#open" });
  await b.send("DOM.setFileInputFiles", { nodeId: input.nodeId, files: [file] });
  await until("after Open, A1 shows the workbook", cell("A1"), String(book.sheets.Sheet1.A1));
  return {
    b, js, until, done, errors,
    close() { if (errors.length) fail("the page threw: " + errors.join(" | ")); b.close(); server.close(); rmSync(dir, { recursive: true, force: true }); },
    hold() { holding = true; },
    async waitHeld(what) { for (let t = 0; t < 100 && !held.length; t++) await sleep(50); if (!held.length) fail(what + ": the page sent no recompute"); },
    async release() { holding = false; for (const id of held.splice(0)) await b.send("Fetch.continueRequest", { requestId: id }); },
    get computes() { return computes; },
    get pending() { return held.length; },
  };
}

// The text a cell shows, the open editor (if any) and where the keyboard is.
export const cell = (ref) => `document.querySelector('#grid td[data-ref="${ref}"]')?.textContent.trim() ?? null`;
export const editor = `(() => { const i = document.querySelector('#grid td input');
  return i ? { ref: i.closest('td').dataset.ref, value: i.value, caret: [i.selectionStart, i.selectionEnd],
               focused: document.activeElement === i } : null; })()`;
export const focusIn = `document.activeElement === document.body ? "BODY" : document.querySelector('#grid').contains(document.activeElement) ? "grid" : document.activeElement.tagName`;

// One real key press (keyDown, char, keyUp) as a keyboard sends it; `gap` ms after it (a user typing).
const VK = { Enter: 13, ArrowLeft: 37, ArrowRight: 39, ArrowDown: 40, ArrowUp: 38, F2: 113, End: 35, Home: 36, Escape: 27 };
export async function press(b, key, gap = 0) {
  const special = key.length > 1;
  const code = VK[key] ?? (/^[a-z0-9]$/i.test(key) ? key.toUpperCase().charCodeAt(0) : 0); // punctuation: by its text
  await b.send("Input.dispatchKeyEvent", { type: special ? "rawKeyDown" : "keyDown", key, windowsVirtualKeyCode: code, ...(special ? {} : { text: key }) });
  await b.send("Input.dispatchKeyEvent", { type: "keyUp", key, windowsVirtualKeyCode: code });
  if (gap) await sleep(gap);
}
export async function type(b, text, gap = 120) { for (const ch of text) await press(b, ch, gap); }
```
a_v1_tk_b1_kept.sh and a_v1_tk_b2_open.sh run `node` on these from the repo root and fail without node. a_v1_tk_suite.sh is a-v1-big-sheets' suite check (the product's tests must exist in tests/e2e/ui/test_typing_kept.py, be discovered by ./test.sh, start the browser named by $CHROME, not be skipped, and pass).

- **Reuses:** The grid's own editor (its input and its Enter/Escape listeners), draw() and show(), and the page's recompute path through setState, all unchanged; a-r2's browser helper (a_r2_cdp.mjs) and the product's browser.mjs for the tests.
- **Removes:** The redraw throwing away an open cell editor.
- **Rejected:** none recorded

## 4. Work items

### `wi-a-v1-typing-kept-1`: Keep the cell editor through a recompute

When a recompute redraws the grid while a cell is being typed into, the grid puts the same editor back with its text, cursor and focus, so no keystroke is lost and the cell is saved only on Enter.

Status: accepted

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-tk-b1` | b1 | `tests/e2e/ui/checks/a_v1_tk_b1_kept.sh` | red | — |
| `ac-tk-b2` | b2 | `tests/e2e/ui/checks/a_v1_tk_b2_open.sh` | red | — |

### `wi-a-v1-typing-kept-2`: Browser test for typing during a recompute

Adds tests/e2e/ui/test_typing_kept.py (and typing_kept.mjs), run by ./test.sh in headless Chrome, so the product keeps every keystroke typed while it recomputes.

Status: accepted · depends on `wi-a-v1-typing-kept-1`

| AC | Covers | Check | Red on base | On product |
| --- | --- | --- | --- | --- |
| `ac-tk-suite` | b1, b2 | `tests/e2e/ui/checks/a_v1_tk_suite.sh` | red | — |
| `ac-tk-judge` | b1, b2 | `judge:Usefulness only (not Calc fidelity): through the page as shipped (python3 web/io/serve.py, /io/index.html), on a workbook big enough that a recompute takes a second or more, can an ordinary user fill in a column of numbers and formulas at their normal typing speed, pressing Enter after each and going straight on, without ever losing or garbling what they typed, finding a half-typed formula saved, or having the keyboard stop working? Answer yes or no with what you tried.` | judged | — |

**Acceptance**, against the landed checks:

| Result | Bullet | Text | Landed checks |
| --- | --- | --- | --- |
| not yet | b1 | text typed into a cell while a recompute is in flight is kept in full and committed only when the user presses Enter | no landed check |
| not yet | b2 | after a recompute returns, the cell being edited is still open with its text and caret, and focus stays in the grid | no landed check |

## 5. Out of scope and risks

- **Out of scope:** making the engine faster
- **Non-functional:** none beyond matching Calc and the existing tests
- **Path scope:** `exp-a:web/grid/**`, `exp-a:web/io/index.html`, `exp-a:tests/e2e/ui/**`, `exp-a:tests/web/grid/**`, `exp-a:tests/web/io/**`

## 6. Evidence

| Role | Who |
| --- | --- |
| Planned | `plan-a@alebairos` |
| Certified | `gate-a@alebairos` |
| Implemented `wi-a-v1-typing-kept-1` | — |
| Reviewed `wi-a-v1-typing-kept-1` | — |
| Implemented `wi-a-v1-typing-kept-2` | — |
| Reviewed `wi-a-v1-typing-kept-2` | — |

Product checks: not recorded yet.

Outcome report: none yet.

## 7. The decision

Nothing waits on you.

## 8. Metrics

- Lead time: 3 h 32 min so far
- Loops: 0
- Waste: 0 min
- Size: nothing landed yet
