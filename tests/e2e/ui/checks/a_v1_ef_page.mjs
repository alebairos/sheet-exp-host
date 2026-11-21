// b2 in a real browser (plan a-v1-engine-failure): on web/io/index.html as web/io/serve.py serves it, Open
// book.json (A1 2, A2 =A1*3, C1 =SUM(A1:A2)). In the formula bar enter the 1000-term sum =1+1+...+1 into D1:
// D1 shows Calc's 1000. Enter the 4097-term sum into D2: D2 shows Calc's Err:512. Then click A1 and type 7,
// Enter, in the grid: A2 and C1 recompute to Calc's 21 and 28, D1 still shows 1000, the message line
// (#message) shows no "Could not" and the page throws nothing. Values: tests/eval/checks/a_v1_ef_calc.json.
import { mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { findBrowser, serve, launch, sleep } from "./a_r2_cdp.mjs";

const CALC = JSON.parse(readFileSync(join(dirname(fileURLToPath(import.meta.url)), "../../../eval/checks/a_v1_ef_calc.json"), "utf8"));
const R = CALC.results, sum = (n) => "=" + Array(n).fill("1").join("+");
const fail = (m) => { console.log("FAIL " + m); process.exit(1); };
const browser = findBrowser();
if (!browser) fail("no browser: set CHROME or put google-chrome or chromium on PATH");
const file = join(mkdtempSync(join(tmpdir(), "a-v1-ef-")), "book.json");
writeFileSync(file, JSON.stringify({ sheets: { Sheet1: { A1: 2, A2: "=A1*3", C1: "=SUM(A1:A2)" } } }));
const server = await serve();
const b = await launch(browser);
const errors = [];
b.on("Runtime.exceptionThrown", (p) => errors.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text));
const done = (code) => { b.close(); server.close(); process.exit(code); };
try {
  await b.send("Runtime.enable"); await b.send("Page.enable");
  const js = async (e) => (await b.send("Runtime.evaluate", { expression: e, returnByValue: true, awaitPromise: true })).result.value;
  const until = async (what, e, want, tries = 150) => { let got; for (let t = 0; t < tries; t++) { got = await js(e); if (got === want) return; await sleep(100); } fail(`${what}: wanted ${JSON.stringify(want)}, the page shows ${JSON.stringify(got)}`); };
  const cell = (ref) => `document.querySelector('#grid td[data-ref="${ref}"]')?.textContent.trim() ?? null`;
  const message = `document.getElementById("message")?.textContent ?? ""`;
  const click = async (sel) => {
    const r = await js(`(() => { const e = document.querySelector(${JSON.stringify(sel)}); if (!e) return null; const r = e.getBoundingClientRect(); return {x: r.x + r.width / 2, y: r.y + r.height / 2}; })()`);
    if (!r) fail(`the page has no ${sel}`);
    for (const type of ["mousePressed", "mouseReleased"]) await b.send("Input.dispatchMouseEvent", { type, ...r, button: "left", clickCount: 1 });
  };
  const key = async (k, code, vk, text) => { await b.send("Input.dispatchKeyEvent", { type: "keyDown", key: k, code, windowsVirtualKeyCode: vk, text }); await b.send("Input.dispatchKeyEvent", { type: "keyUp", key: k, code, windowsVirtualKeyCode: vk }); };
  const BAR = '#formula-bar input[aria-label="Formula"]';
  const inBar = async (ref, text) => {
    await click(`#grid td[data-ref="${ref}"]`);
    await until(`the formula bar follows the selection to ${ref}`, `document.querySelector('#formula-bar .ref')?.textContent.trim() ?? ""`, ref, 30);
    await click(BAR);
    await b.send("Input.dispatchKeyEvent", { type: "rawKeyDown", commands: ["selectAll"], key: "a", code: "KeyA", modifiers: 2 });
    await b.send("Input.dispatchKeyEvent", { type: "keyUp", key: "a", code: "KeyA", modifiers: 2 });
    await b.send("Input.insertText", { text });
    await key("Enter", "Enter", 13);
  };
  await b.send("Page.navigate", { url: server.url + "/io/index.html" });
  await until("the page loads with its grid", `!!document.querySelector('#grid td[data-ref="A1"]')`, true);
  const doc = await b.send("DOM.getDocument");
  const input = await b.send("DOM.querySelector", { nodeId: doc.root.nodeId, selector: "#open" });
  await b.send("DOM.setFileInputFiles", { nodeId: input.nodeId, files: [file] });
  await until("after Open, C1 shows Calc's 8", cell("C1"), R.C1.shown);
  // Some desktop Chromium builds open an extension tab that hides the page: let it settle, keep the page in front.
  await sleep(1500); await b.send("Page.bringToFront");
  await inBar("D1", sum(1000));
  await until("the 1000-term sum in D1 shows Calc's value", cell("D1"), R.B1.shown);
  await inBar("D2", sum(4097));
  await until("the 4097-term sum in D2 shows Calc's error", cell("D2"), R.B7.error);
  await click('#grid td[data-ref="A1"]');
  await key("7", "Digit7", 55, "7");
  await key("Enter", "Enter", 13);
  await until("after A1 = 7, A2 =A1*3 shows Calc's value", cell("A2"), CALC.after_A1_7.A2.shown);
  await until("after A1 = 7, C1 =SUM(A1:A2) shows Calc's value", cell("C1"), CALC.after_A1_7.C1.shown);
  await until("D1 still shows 1000", cell("D1"), R.B1.shown, 10);
  const m = await js(message);
  if (/Could not/.test(m)) fail("the message line shows " + JSON.stringify(m));
  if (errors.length) fail("the page threw: " + errors.join(" | "));
  console.log("ok b2 page: long formulas compute (1000, Err:512) and later edits keep computing (21, 28)");
  done(0);
} catch (e) { console.log("FAIL " + (e.stack || e)); done(1); }
