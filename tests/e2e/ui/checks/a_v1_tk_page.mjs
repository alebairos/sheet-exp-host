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
