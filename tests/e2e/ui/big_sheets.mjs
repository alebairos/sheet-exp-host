// Big sheets in a real browser (a-v1-big-sheets), with real wheel, clicks and keys, on web/io/index.html as
// serve.py serves it: open a 2001-row, 12-column CSV, scroll to its last cell and back, move with the arrows and
// PageDown/PageUp past the visible edge, and edit row 2001 so the formulas reading it recompute.
// Expected values are LibreOffice Calc's (tests/e2e/ui/checks/a_v1_bs_calc.json, from a_v1_bs_probe.py).
// Exits 0 printing "ok", 1 with a FAIL line naming the step that did not happen, 2 when there is no browser.
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { findBrowser, serve, launch, sleep } from "./browser.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));
const ROOT = join(HERE, "..", "..", "..");
const CALC = JSON.parse(readFileSync(join(HERE, "checks", "a_v1_bs_calc.json"), "utf8"));
const fail = (m) => { throw new Error(m); };
const browser = findBrowser();
if (!browser) { console.log("no browser: set CHROME or put google-chrome or chromium on PATH"); process.exit(2); }

// big.csv: header colA..colL, then rows 2..2001, cell = row*100 + column index (A2 = 200, L2001 = 200111).
const lines = [[...Array(12)].map((_, c) => "col" + String.fromCharCode(65 + c)).join(",")];
for (let r = 2; r <= 2001; r++) lines.push([...Array(12)].map((_, c) => r * 100 + c).join(","));
const dir = mkdtempSync(join(tmpdir(), "e2e-ui-big-"));
const file = join(dir, "big.csv");
writeFileSync(file, lines.join("\n") + "\n");

const server = await serve(ROOT);
let b = null;
let code = 1;
try {
  b = await launch(browser);
  const thrown = [];
  b.on("Runtime.exceptionThrown", (p) => thrown.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text));
  await b.send("Runtime.enable");
  await b.send("Page.enable");
  const js = async (expr) => (await b.send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })).result.value;
  // Some desktop Chromium builds open an extension's tab over the test page soon after start; a hidden page
  // stalls its input, timers and frames. Before every key, wheel step and wait, any other tab is closed and the page
  // brought back to the front (a no-op where no such tab opens, as on CI).
  const front = async () => {
    let closed = 0;
    for (const t of (await b.send("Target.getTargets")).targetInfos) {
      if (t.type === "page" && t.targetId !== b.targetId) {
        await b.send("Target.closeTarget", { targetId: t.targetId }).catch(() => {});
        closed++;
      }
    }
    if (!closed && (await js("document.visibilityState")) === "visible") return;
    await b.send("Page.bringToFront");
  };
  const until = async (what, expr, want, tries = 100) => {
    let got;
    for (let t = 0; t < tries; t++) { await front(); got = await js(expr); if (got === want) return; await sleep(100); }
    fail(`${what}: wanted ${JSON.stringify(want)}, the page shows ${JSON.stringify(got)}`);
  };
  const text = (ref) => `document.querySelector('#grid td[data-ref="${ref}"]')?.textContent.trim() ?? null`;
  const selected = `document.querySelector('#grid td.selected')?.dataset.ref ?? null`;
  // The user sees an element: inside the window, and the point at its centre hits it (not clipped or covered).
  const seen = (sel, label) => `(() => [...document.querySelectorAll(${JSON.stringify(sel)})]
    .filter((e) => ${label === undefined ? "true" : `e.textContent.trim() === ${JSON.stringify(label)}`})
    .some((e) => { const r = e.getBoundingClientRect();
      if (r.width < 4 || r.height < 4 || r.left < 0 || r.top < 0 || r.right > innerWidth || r.bottom > innerHeight) return false;
      const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2); return !!hit && (hit === e || e.contains(hit)); }))()`;
  const seenCell = (ref) => seen(`#grid td[data-ref="${ref}"]`);
  const VK = { ArrowDown: 40, ArrowUp: 38, ArrowLeft: 37, ArrowRight: 39, PageDown: 34, PageUp: 33, Enter: 13 };
  const press = async (key) => {
    await front();
    for (const type of ["keyDown", "keyUp"]) {
      const p = { type, key, code: key, windowsVirtualKeyCode: VK[key] ?? key.toUpperCase().charCodeAt(0) };
      if (type === "keyDown" && key.length === 1) p.text = key;
      await b.send("Input.dispatchKeyEvent", p);
    }
  };
  // A key that moves the selection: it lands on `want` and the view follows it.
  const step = async (key, want) => {
    await press(key);
    await until(`${key} selects ${want}`, selected, want, 50);
    await until(`after ${key} the user sees ${want}`, seenCell(want), true, 20);
  };
  // Typing into the selected cell, as a user does: the first key opens the editor, Enter commits.
  const type = async (s) => {
    await press(s[0]);
    if (s.length > 1) await b.send("Input.insertText", { text: s.slice(1) });
    await press("Enter");
  };
  const click = async (ref) => {
    const at = await js(`(() => { const r = document.querySelector('#grid td[data-ref="${ref}"]').getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`);
    for (const t of ["mousePressed", "mouseReleased"]) await b.send("Input.dispatchMouseEvent", { type: t, ...at, button: "left", clickCount: 1 });
    await until(`clicking ${ref} selects it`, selected, ref);
  };
  const row = (ref) => Number(/\d+$/.exec(ref)[0]);

  await b.send("Page.navigate", { url: server.url + "/io/index.html" });
  await until("the page loads with its grid", `!!document.querySelector('#grid td[data-ref="A1"]')`, true);
  // 1. Open big.csv through the file input, as a user picks it.
  const doc = await b.send("DOM.getDocument");
  const input = await b.send("DOM.querySelector", { nodeId: doc.root.nodeId, selector: "#open" });
  if (!input.nodeId) fail("the page has no #open file input");
  await b.send("DOM.setFileInputFiles", { nodeId: input.nodeId, files: [file] });
  await until("after Open, A2 shows its CSV value", text("A2"), CALC.csv.A2);

  // 2. M1 sums column B over all 2001 rows: right past the old 8-column edge to M1, type the formula.
  await click("A1");
  for (const c of "BCDEFGHIJKLM") await step("ArrowRight", c + "1");
  await type(CALC.formulas.M1);
  await until(`M1 ${CALC.formulas.M1} shows Calc's ${CALC.before.M1}`, text("M1"), CALC.before.M1);

  // 3. The mouse wheel reaches row 2001 and column L, with their headers in view, and comes back to A1.
  await b.send("Page.bringToFront");
  const box = await js(`(() => { const r = document.getElementById("grid").getBoundingClientRect();
    return {x: Math.min(r.left + r.width / 2, innerWidth / 2), y: Math.min(r.top + 200, innerHeight / 2)}; })()`);
  const frame = `new Promise((ok) => requestAnimationFrame(() => setTimeout(() => ok(true), 0)))`;
  const steps = [];
  const wheel = async (deltaX, deltaY) => {
    const t0 = performance.now();
    await b.send("Input.dispatchMouseEvent", { type: "mouseWheel", ...box, deltaX, deltaY });
    await js(frame);
    steps.push(performance.now() - t0);
  };
  for (let i = 0; i < 400 && !(await js(seenCell("A2001"))); i++) await wheel(0, 400);
  for (let i = 0; i < 100 && !(await js(seenCell("L2001"))); i++) await wheel(300, 0);
  await until("wheeling down and right shows L2001", seenCell("L2001"), true, 10);
  await until("L2001 shows its CSV value", text("L2001"), CALC.csv.L2001);
  await until("the row header 2001 is in view", seen("#grid th", "2001"), true, 10);
  await until("the column header L is in view", seen("#grid th", "L"), true, 10);
  for (let i = 0; i < 400 && !(await js(seenCell("A1"))); i++) await wheel(-3000, -400);
  await until("wheeling back up and left shows A1 again", seenCell("A1"), true, 10);
  const sorted = [...steps].sort((x, y) => x - y);
  const median = sorted[sorted.length >> 1];
  // The plan's bound is 100 ms a step; the median is held to it so one slow frame on a busy runner does not fail.
  if (median >= 100) fail(`scrolling is slow: the median wheel step took ${median.toFixed(1)} ms (bound 100 ms)`);

  // 4. ArrowDown walks past the first screen; PageDown jumps a screen at a time to row 2001; PageUp goes back.
  await click("A1");
  for (let r = 2; r <= 40; r++) await step("ArrowDown", "A" + r);
  let at = 40;
  for (let i = 0; i < 300 && at < 2001; i++) {
    await press("PageDown");
    const ref = await js(selected);
    if (!ref || !ref.startsWith("A") || row(ref) < at + 10) fail(`PageDown from A${at} selects ${ref}, wanted column A at least 10 rows further`);
    await until(`after PageDown the user sees ${ref}`, seenCell(ref), true, 20);
    at = row(ref);
  }
  if (at < 2001) fail(`PageDown from A40 reaches only A${at}`);
  for (; at > 2001; at--) await step("ArrowUp", "A" + (at - 1));
  await press("PageUp");
  const up = await js(selected);
  if (!up || row(up) > 1991) fail(`PageUp from A2001 selects ${up}, wanted at least 10 rows up`);
  await until(`after PageUp the user sees ${up}`, seenCell(up), true, 20);
  for (at = row(up); at < 2001; at++) await step("ArrowDown", "A" + (at + 1));

  // 5. Row 2001: M2001 reads B2001; typing 5 into B2001 recomputes it and the sum at the top.
  for (const c of "BCDEFGHIJKLM") await step("ArrowRight", c + "2001");
  await type(CALC.formulas.M2001);
  await until(`M2001 ${CALC.formulas.M2001} shows Calc's ${CALC.before.M2001}`, text("M2001"), CALC.before.M2001);
  await step("ArrowUp", "M2001");
  for (const c of "LKJIHGFEDCB") await step("ArrowLeft", c + "2001");
  await type("5");
  await until("B2001 holds the typed 5", text("B2001"), CALC.edit.B2001);
  await until(`M2001 recomputes to Calc's ${CALC.after.M2001}`, text("M2001"), CALC.after.M2001);
  await until("after Enter the selection is B2002 and stays there after the recompute", selected, "B2002", 10);
  for (at = 2002; at > 1;) {
    await press("PageUp");
    const ref = await js(selected);
    if (!ref || !ref.startsWith("B") || (row(ref) > at - 10 && row(ref) !== 1)) fail(`PageUp from B${at} selects ${ref}`);
    at = row(ref);
  }
  for (const c of "CDEFGHIJKLM") await step("ArrowRight", c + "1");
  await until(`M1 recomputes to Calc's ${CALC.after.M1}`, text("M1"), CALC.after.M1);

  if (thrown.length) fail("the page threw: " + thrown.join(" | "));
  console.log(`ok big sheets: wheel to L2001 and back (${steps.length} steps, median ${median.toFixed(1)} ms), arrows and PageDown/PageUp to row 2001, B2001 := 5 gives M2001 ${CALC.after.M2001} and M1 ${CALC.after.M1}`);
  code = 0;
} catch (e) {
  console.log("FAIL " + (e && e.message ? e.message : e));
} finally {
  if (b) b.close();
  server.close();
  rmSync(dir, { recursive: true, force: true });
}
process.exit(code);
