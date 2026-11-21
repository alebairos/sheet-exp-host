// b1 in a real browser (plan a-v1-csv-text): on web/io/index.html as web/io/serve.py serves it, Open (#open)
// bank.csv (tests/web/io/checks/a_v1_ct_bank.csv); the grid shows Calc's import (E2 2134, C2 4.5); Save CSV
// (#save-csv) downloads bank.csv identical to the file. Click G2, type =E2+1 and Enter: G2 shows Calc's 2135;
// Save CSV again: every field of the file is saved exactly as written and G2 as 2135. The page throws nothing.
import { mkdtempSync, readFileSync, existsSync, rmSync, copyFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { findBrowser, serve, launch, sleep } from "./a_r2_cdp.mjs";

const IO = join(dirname(fileURLToPath(import.meta.url)), "../../../web/io/checks");
const CALC = JSON.parse(readFileSync(join(IO, "a_v1_ct_calc.json"), "utf8"));
const { fields } = await import("../../../web/io/checks/a_v1_ct_b1_fields.mjs");
const fail = (m) => { console.log("FAIL " + m); process.exit(1); };
const browser = findBrowser();
if (!browser) fail("no browser: set CHROME or put google-chrome or chromium on PATH");
const dir = mkdtempSync(join(tmpdir(), "a-v1-ct-")), saved = join(dir, "saved"), file = join(dir, "bank.csv");
copyFileSync(join(IO, "a_v1_ct_bank.csv"), file);
const FILE = readFileSync(file, "utf8");
const server = await serve();
const b = await launch(browser);
const errors = [];
b.on("Runtime.exceptionThrown", (p) => errors.push(p.exceptionDetails.exception?.description ?? p.exceptionDetails.text));
const done = (code) => { b.close(); server.close(); process.exit(code); };
try {
  await b.send("Runtime.enable"); await b.send("Page.enable");
  await b.send("Browser.setDownloadBehavior", { behavior: "allow", downloadPath: saved });
  const js = async (e) => (await b.send("Runtime.evaluate", { expression: e, returnByValue: true, awaitPromise: true })).result.value;
  const until = async (what, e, want) => { let got; for (let t = 0; t < 100; t++) { got = await js(e); if (got === want) return; await sleep(100); } fail(`${what}: wanted ${JSON.stringify(want)}, the page shows ${JSON.stringify(got)}`); };
  const cell = (ref) => `document.querySelector('#grid td[data-ref="${ref}"]')?.textContent.trim() ?? null`;
  const save = async () => {
    rmSync(saved, { recursive: true, force: true });
    await js(`document.getElementById("save-csv").click()`);
    const out = join(saved, "bank.csv");
    for (let t = 0; t < 100 && !existsSync(out); t++) await sleep(100);
    await sleep(200);
    if (!existsSync(out)) fail("Save CSV downloaded no bank.csv");
    return readFileSync(out, "utf8");
  };
  await b.send("Page.navigate", { url: server.url + "/io/index.html" });
  await until("the page loads with its grid", `!!document.querySelector('#grid td[data-ref="A1"]')`, true);
  const doc = await b.send("DOM.getDocument");
  const input = await b.send("DOM.querySelector", { nodeId: doc.root.nodeId, selector: "#open" });
  await b.send("DOM.setFileInputFiles", { nodeId: input.nodeId, files: [file] });
  await until("after Open, E2 shows Calc's import of 02134", cell("E2"), CALC.imported.E2);
  await until("after Open, C2 shows Calc's import of 4.50", cell("C2"), CALC.imported.C2);
  // Some desktop Chromium builds open an extension tab that hides the page: let it settle, keep the page in front.
  await sleep(1500); await b.send("Page.bringToFront");
  const first = await save();
  if (first !== FILE) fail(`Save CSV right after Open is not the file: got ${JSON.stringify(first)}`);
  const r = await js(`(() => { const r = document.querySelector('#grid td[data-ref="G2"]').getBoundingClientRect(); return {x: r.x + r.width / 2, y: r.y + r.height / 2}; })()`);
  for (const type of ["mousePressed", "mouseReleased"]) await b.send("Input.dispatchMouseEvent", { type, ...r, button: "left", clickCount: 1 });
  await b.send("Input.dispatchKeyEvent", { type: "keyDown", key: "=", code: "Equal", text: "=", windowsVirtualKeyCode: 187 });
  await b.send("Input.dispatchKeyEvent", { type: "keyUp", key: "=", code: "Equal", windowsVirtualKeyCode: 187 });
  await b.send("Input.insertText", { text: "E2+1" });
  for (const type of ["keyDown", "keyUp"]) await b.send("Input.dispatchKeyEvent", { type, key: "Enter", code: "Enter", windowsVirtualKeyCode: 13 });
  await until(`G2 =E2+1 shows Calc's ${CALC.shown.G2}`, cell("G2"), CALC.shown.G2);
  const out = fields(await save()), orig = fields(FILE);
  orig.forEach((row, i) => row.forEach((f, c) => { if ((out[i]?.[c] ?? "") !== f) fail(`after the edit, ${String.fromCharCode(65 + c)}${i + 1} was ${JSON.stringify(f)} in the file, Save CSV writes ${JSON.stringify(out[i]?.[c])}`); }));
  if (out[1]?.[6] !== CALC.shown.G2) fail(`Save CSV writes G2 as ${JSON.stringify(out[1]?.[6])}, Calc shows ${CALC.shown.G2}`);
  if (errors.length) fail("the page threw: " + errors.join(" | "));
  console.log("ok b1 page: bank.csv saves back byte for byte; after =E2+1 in G2 (2135) every field of the file is unchanged");
  done(0);
} catch (e) { console.log("FAIL " + (e.stack || e)); done(1); }
