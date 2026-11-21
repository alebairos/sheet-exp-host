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
